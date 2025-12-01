import tkinter as tk
import threading
import time
import win32gui
import win32process
import psutil
from pathlib import Path
import re
import tkinter.font as tkFont
import pydirectinput
import json
from colorama import init, Fore, Style

gui_writer = None

def set_gui_writer(writer):
	global gui_writer
	gui_writer = writer

def module_print(text, color="white"):
	if gui_writer:
		gui_writer.write(text, tag=color)
	else:
		print(text)
		
def load_core_config():
	core_config_path = Path(__file__).parent.parent / "css_enhancer_config.json"
	if not core_config_path.exists():
		module_print(f"Core config not found at {core_config_path}", "red")
		return None
	text = core_config_path.read_text(encoding="utf-8")
	text = re.sub(r'//.*', '', text)
	text = re.sub(r',(\s*[\]}])', r'\1', text)
	lines = [line for line in text.splitlines() if line.strip()]
	try:
		return json.loads("\n".join(lines))
	except Exception as e:
		return None

core_config = load_core_config()
if core_config and "game_path" in core_config:
	GAME_PATH = Path(core_config["game_path"])
else:
	GAME_PATH = Path(".")

CONFIG_FILE = Path(__file__).parent / "configs" / "playerlist_config.jsonc"
DEFAULT_CONFIG = r"""{
	"button_press_interval": 1,
	"team_t_pos": {"x": 10, "y": 50},
	"team_ct_pos": {"x": 400, "y": 50},
	"enable_t": 1,
	"enable_ct": 1,
	"team_t_limit": 10,
	"team_ct_limit": 10,
	"font_size": 18,
	"overlay_width": 800,
	"keybind": "f7"
}"""

def load_config(path: Path):
	if not path.exists():
		path.write_text(DEFAULT_CONFIG, encoding="utf-8")
	text = path.read_text(encoding="utf-8")
	text = re.sub(r'//.*', '', text)
	text = re.sub(r',(\s*[\]}])', r'\1', text)
	lines = [line for line in text.splitlines() if line.strip()]
	clean_text = "\n".join(lines)
	return json.loads(clean_text)

CONFIG = load_config(CONFIG_FILE)

BUTTON_PRESS_INTERVAL = CONFIG.get("button_press_interval", 1)
TEAM_T_POS = CONFIG.get("team_t_pos", {"x":10,"y":50})
TEAM_CT_POS = CONFIG.get("team_ct_pos", {"x":400,"y":50})
ENABLE_T = CONFIG.get("enable_t",1)
ENABLE_CT = CONFIG.get("enable_ct",1)
TEAM_T_LIMIT = CONFIG.get("team_t_limit", 10)
TEAM_CT_LIMIT = CONFIG.get("team_ct_limit", 10)
FONT_SIZE = CONFIG.get("font_size", 18)
OVERLAY_WIDTH = CONFIG.get("overlay_width", 800)
KEYBIND = CONFIG.get("keybind", "f7")

FONT_NAME = "Lucida Console"
TARGET_EXE_NAME = "cstrike_win64.exe"
BOTTOM_MARGIN = 80

stop_module_triggered = False

re_var = re.compile(r'^(m_iHealth|m_szName|m_iTeam)\[(\d+)\].*\((.*)\)$')

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

def parse_console_line(line):
	m = re_var.match(line)
	if not m:
		return None
	var, idx, value = m.groups()
	idx = int(idx)
	return var, idx, value

class Overlay:
	def __init__(self, master, x=0, y=None):
		self.root = tk.Toplevel(master)
		self.root.overrideredirect(True)
		self.root.attributes("-topmost", True)
		self.root.attributes("-transparentcolor", "black")
		self.root.configure(bg="black")

		screen_w = self.root.winfo_screenwidth()
		screen_h = self.root.winfo_screenheight()

		self.x = x
		self.y = y if y is not None else screen_h - BOTTOM_MARGIN

		self.canvas = tk.Canvas(self.root, width=OVERLAY_WIDTH, height=200, 
								bg='black', highlightthickness=0)
		self.canvas.pack(fill="both", expand=True)

		self.font_obj = tkFont.Font(family=FONT_NAME, size=FONT_SIZE, weight="bold")
		self.lock = threading.Lock()

		self.team_t = []
		self.team_ct = []
		self.show_until = 0

		self.update_overlay()

	def scale_color(self, base_hex, health, min_hp, max_hp):
		factor = 1.0 if max_hp == min_hp else (health - min_hp) / (max_hp - min_hp)
		factor = max(0.3, min(1.0, 0.3 + 0.7 * factor))
		r = int(int(base_hex[1:3], 16) * factor)
		g = int(int(base_hex[3:5], 16) * factor)
		b = int(int(base_hex[5:7], 16) * factor)
		return f"#{r:02x}{g:02x}{b:02x}"

	def draw_team_line(self, x, y, text, team, health, min_hp, max_hp):
		base_color = "#ff4040" if team == 2 else "#00aaff"
		color = self.scale_color(base_color, health, min_hp, max_hp)
		self.canvas.create_text(x, y, text=text, font=self.font_obj, fill=color, anchor="nw")

	def update_overlay(self):
		active_exe = get_active_window_exe()
		with self.lock:
			self.canvas.delete("all")
			now = time.time()
			if active_exe == TARGET_EXE_NAME.lower() and now < self.show_until:
				y_t = TEAM_T_POS["y"]
				y_ct = TEAM_CT_POS["y"]

				t_hps = [hp for _, hp in self.team_t]
				ct_hps = [hp for _, hp in self.team_ct]

				min_t, max_t = (min(t_hps), max(t_hps)) if t_hps else (0, 1)
				min_ct, max_ct = (min(ct_hps), max(ct_hps)) if ct_hps else (0, 1)

				if ENABLE_T:
					for name, hp in self.team_t[:TEAM_T_LIMIT]:
						self.draw_team_line(TEAM_T_POS["x"], y_t, f"{name}: {hp}", 2, hp, min_t, max_t)
						y_t += FONT_SIZE + 4

				if ENABLE_CT:
					for name, hp in self.team_ct[:TEAM_CT_LIMIT]:
						self.draw_team_line(TEAM_CT_POS["x"], y_ct, f"{name}: {hp}", 3, hp, min_ct, max_ct)
						y_ct += FONT_SIZE + 4

				height = max(y_t, y_ct, 50)
				self.root.geometry(f"{OVERLAY_WIDTH}x{height}+{self.x}+{self.y - height}")
				self.root.deiconify()
			else:
				self.root.withdraw()

		self.root.after(100, self.update_overlay)

	def update_teams(self, players):
		with self.lock:
			team_t, team_ct = [], []
			for p in players.values():
				if p["name"].lower() == "unconnected":
					continue
				if p["health"] > 1 and p["team"] in (2, 3):
					if p["team"] == 2:
						team_t.append((p["name"], p["health"]))
					else:
						team_ct.append((p["name"], p["health"]))
			team_t.sort(key=lambda x: x[1])
			team_ct.sort(key=lambda x: x[1])
			self.team_t = team_t
			self.team_ct = team_ct
			self.show_until = time.time() + 2

_overlay_instance = None

def init_overlay(master):
	global _overlay_instance
	if _overlay_instance is None:
		_overlay_instance = Overlay(master)

def press_keybind():
	global stop_module_triggered
	while True:
		if stop_module_triggered:
			break

		if get_active_window_exe() == TARGET_EXE_NAME.lower():
			pydirectinput.keyDown(KEYBIND)
			pydirectinput.keyUp(KEYBIND)

		time.sleep(BUTTON_PRESS_INTERVAL)

_players_state = {}

def ensure_css_enhancer_cfg_lines():
	try:
		cfg_dir = GAME_PATH / "cfg"
		cfg_dir.mkdir(parents=True, exist_ok=True)
		cfg_file = cfg_dir / "css_enhancer.cfg"

		required_lines = [
			'con_filter_enable 1',
			'con_filter_text_out "m_"',
			f'bind {KEYBIND} g15_dumpplayer'
		]

		existing_lines = []
		if cfg_file.exists():
			existing_lines = [line.strip() for line in cfg_file.read_text(encoding="utf-8").splitlines()]

		with cfg_file.open("a", encoding="utf-8") as f:
			for line in required_lines:
				if line not in existing_lines:
					f.write(line + "\n")

	except Exception as e:
		module_print(f"Failed to write css_enhancer.cfg: {e}")

def on_new_log(line, master=None):
	global _overlay_instance, _players_state, stop_module_triggered
	
	if stop_module_triggered:
		return
		
	if _overlay_instance is None:
		if master is None:
			return
		init_overlay(master)
		threading.Thread(target=press_keybind, daemon=True).start()
		ensure_css_enhancer_cfg_lines()

	py_line = line.decode("utf-8") if isinstance(line, bytes) else str(line)
	
	if py_line.strip() == "Must run with -g15 to enable support for the LCD Keyboard":
		module_print("[Player List] ", "cyan")
		module_print("Stopping module because the game is missing the -g15 launch parameter.", "red")
		stop_module_triggered = True
		return
		
	m = parse_console_line(py_line)
	if m:
		var, idx, value = m
		if idx not in _players_state:
			_players_state[idx] = {"name": "", "health": 0, "team": 0}
		if var == "m_szName":
			_players_state[idx]["name"] = value.strip()
		elif var == "m_iHealth":
			try: _players_state[idx]["health"] = int(value)
			except: _players_state[idx]["health"] = 0
		elif var == "m_iTeam":
			try: _players_state[idx]["team"] = int(value)
			except: _players_state[idx]["team"] = 0

	if _overlay_instance:
		_overlay_instance.update_teams(_players_state)

ensure_css_enhancer_cfg_lines()