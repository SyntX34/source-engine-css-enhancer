import tkinter as tk
import threading
import time
import re
import colorsys
import json
from pathlib import Path
import tkinter.font as tkFont
import win32gui
import win32process
import psutil

CONFIG_FILE = Path(__file__).parent / "configs" / "countdown_config.jsonc"
DEFAULT_CONFIG = r"""{ 
	"overlay_x": 0,				
	"overlay_y": 80,			
	"overlay_width": 800,		
	"font_size": 18,			
	"color_mode": "rainbow",	
	"color": "#ffffff",			
	"update_interval": 50		
}"""

def load_config(path: Path):
	if not path.exists():
		path.write_text(DEFAULT_CONFIG, encoding="utf-8")
	with path.open("r", encoding="utf-8") as f:
		lines = f.readlines()
	clean_lines = []
	for line in lines:
		line_no_comment = re.split(r'(?<!:)//', line)[0].rstrip()
		if line_no_comment:
			clean_lines.append(line_no_comment)
	return json.loads("\n".join(clean_lines))

CONFIG = load_config(CONFIG_FILE)

FONT_NAME = "Lucida Console"
TARGET_EXE_NAME = "cstrike_win64.exe"
BLACKLIST = ["recharge", "recast", "cooldown", "cool", "STEAM_"]

OVERLAY_WIDTH = CONFIG.get("overlay_width", 800)
FONT_SIZE = CONFIG.get("font_size", 18)

def get_active_window_exe():
	try:
		hwnd = win32gui.GetForegroundWindow()
		if hwnd == 0:
			return ""
		_, pid = win32process.GetWindowThreadProcessId(hwnd)
		process = psutil.Process(pid)
		return process.name().lower()
	except Exception:
		return ""

def parse_color(color_str):
	color_str = color_str.strip()
	if color_str.startswith("#"):
		return color_str
	try:
		parts = list(map(int, color_str.split()))
		if len(parts) == 3:
			r, g, b = parts
			return f"#{r:02x}{g:02x}{b:02x}"
	except Exception:
		pass
	return "#ffffff"

def is_player_message(line: str) -> bool:
	if "console:" in line.lower():
		return False
	return any(':' in w for w in line.split()[:3])

def check_blacklist(line: str) -> bool:
	return any(word in line.lower() for word in BLACKLIST)

def parse_countable(line: str):
	if check_blacklist(line) or is_player_message(line):
		return None
	line_lower = line.lower()

	patterns = [
		(r'\bin\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\bfor\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\b(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\s*left\b', 1),
		(r'\bafter\s+(\d+)\s*(s|sec|second|seconds)\b', 0),
		(r'\bhold\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\bresist\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\bdefend\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\bsurvive\s+(\d+)\s*(s|sec|second|seconds|minute|minutes|m)\b', 1),
		(r'\b(\d+)s\b', 0)
	]

	for pattern, convert in patterns:
		match = re.search(pattern, line_lower)
		if match:
			number = int(match.group(1))
			if convert:
				unit = match.group(2)
				if unit in ["minute", "minutes", "m"]:
					return number * 60
			return number
	return None

class Overlay:
	def __init__(self, master):
		self.root = tk.Toplevel(master)
		self.root.overrideredirect(True)
		self.root.attributes('-topmost', True)
		self.root.attributes('-transparentcolor', 'black')
		self.root.configure(bg='black')
		screen_h = self.root.winfo_screenheight()
		self.x = CONFIG.get("overlay_x", 0)
		self.y = screen_h - CONFIG.get("overlay_y", 80)
		self.canvas = tk.Canvas(self.root, width=CONFIG.get("overlay_width", 800), height=10, bg='black', highlightthickness=0)
		self.canvas.pack(fill="both", expand=True)
		self.lock = threading.Lock()
		self.countdowns = []
		self.font_obj = tkFont.Font(family=FONT_NAME, size=CONFIG.get("font_size", 18), weight="bold")
		self.rainbow_phase = 0.0
		self.update()

	def hsv_to_hex(self, h, s=1, v=1):
		r, g, b = colorsys.hsv_to_rgb(h % 1, s, v)
		return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

	def draw_text(self, x, y, text, offset=0):
		color_mode = CONFIG.get("color_mode", "rainbow")
		color_single = parse_color(CONFIG.get("color", "#ffffff"))

		if color_mode == "rainbow":
			self.rainbow_phase = (self.rainbow_phase + 0.008) % 1.0
			hue = (self.rainbow_phase + offset * 0.1) % 1.0
			color = self.hsv_to_hex(hue)
		else:
			color = color_single

		self.canvas.create_text(
			x,
			y,
			text=text,
			font=(FONT_NAME, CONFIG.get("font_size", 18)),
			fill=color,
			anchor="nw"
		)

	def update(self):
		active_exe = get_active_window_exe()
		with self.lock:
			self.canvas.delete("all")
			if active_exe == TARGET_EXE_NAME.lower() and self.countdowns:
				y_offset = 0
				for idx, cd in enumerate(self.countdowns):
					display_text = cd['text'].replace(cd['original'], str(cd['current']))
					self.draw_text(10, y_offset, display_text, offset=idx)
					y_offset += CONFIG.get("font_size", 18) + 6
				screen_h = self.root.winfo_screenheight()
				x = CONFIG.get("overlay_x", 0)
				y = screen_h - CONFIG.get("overlay_y", 80)
				self.root.geometry(f"{CONFIG.get('overlay_width',800)}x{y_offset}+{x}+{y - y_offset}")
				self.root.deiconify()
			else:
				self.root.withdraw()
		self.root.after(CONFIG.get("update_interval", 50), self.update)

	def add_countdown(self, text: str, seconds: int):
		cancel_event = threading.Event()

		match = re.search(r'(\d+)\s*(minute|minutes|m|second|seconds|sec|s)\b', text.lower())
		original_number_str = match.group(1) if match else str(seconds)
		original_unit = match.group(2) if match else ""

		if original_unit in ["minute", "minutes", "m"]:
			converted_text = re.sub(
				r'\b' + re.escape(original_number_str) + r'\s*' + re.escape(original_unit) + r'\b',
				f"{seconds} seconds",
				text,
				flags=re.IGNORECASE
			)
		else:
			converted_text = text

		cd_data = {
			"text": converted_text,
			"original": str(seconds),
			"current": seconds,
			"cancel_event": cancel_event
		}

		with self.lock:
			self.countdowns.append(cd_data)

		def run():
			while cd_data["current"] > 0 and not cancel_event.is_set():
				time.sleep(1)
				cd_data["current"] -= 1
			with self.lock:
				if cd_data in self.countdowns:
					self.countdowns.remove(cd_data)

		threading.Thread(target=run, daemon=True).start()

_overlay_instance = None

def init_overlay(master):
	global _overlay_instance
	if _overlay_instance is None:
		_overlay_instance = Overlay(master)

CONNECT_PTR = re.compile(r"Connecting to \d{1,3}(?:\.\d{1,3}){3}:\d+\.{3}$")
RETRY_MESSAGE = ["Counter-Strike: Source"]

def on_new_log(line, master=None):
	global _overlay_instance
	if _overlay_instance is None:
		if master is None:
			return
		init_overlay(master)
	py_line = line.decode("utf-8") if isinstance(line, bytes) else str(line)
	
	if CONNECT_PTR.search(py_line) or any(msg.lower() in py_line.lower() for msg in RETRY_MESSAGE):
		if _overlay_instance:
			with _overlay_instance.lock:
				for cd in _overlay_instance.countdowns:
					cd["cancel_event"].set()
				_overlay_instance.countdowns.clear()	
		return
	
	seconds = parse_countable(py_line)
	if seconds is not None and _overlay_instance:
		_overlay_instance.add_countdown(py_line, seconds)