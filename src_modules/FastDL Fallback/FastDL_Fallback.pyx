import os
import requests
import bz2
import shutil
import random
import re
import threading
import json
import time
from pathlib import Path

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
	core_path = Path(__file__).parent.parent / "css_enhancer_config.json"
	if not core_path.exists():
		module_print(f"\nCore config not found at {core_path}")
		return None
	with core_path.open("r", encoding="utf-8") as f:
		lines = f.readlines()
	clean_lines = []
	for line in lines:
		line_no_comment = re.split(r'(?<!:)//', line)[0].rstrip()
		if line_no_comment:
			clean_lines.append(line_no_comment)
	try:
		return json.loads("\n".join(clean_lines))
	except Exception as e:
		return None

core_config = load_core_config()
if core_config and "game_path" in core_config:
	GAME_PATH = Path(core_config["game_path"])
else:
	GAME_PATH = Path(".")

DOWNLOAD_PATH = GAME_PATH / "download/maps"
os.makedirs(DOWNLOAD_PATH, exist_ok=True)

CORE_PARENT = Path(__file__).parent.parent
BASE_URLS_FILE = CORE_PARENT / "modules" / "FastDL_Fallback" / "services.txt"

with open(BASE_URLS_FILE, "r", encoding="utf-8") as f:
	base_urls = [line.strip().rstrip("/") + "/" for line in f if line.strip()]

random.shuffle(base_urls)

def download_and_extract_map(map_name: str):
	file_name_bz2 = map_name + ".bz2"
	file_path_bz2 = DOWNLOAD_PATH / file_name_bz2
	downloaded_and_extracted = False

	for base_url in base_urls:
		url = base_url + file_name_bz2

		if downloaded_and_extracted:
			break

		try:
			resp = requests.get(url, stream=True, timeout=10)
			if resp.status_code == 200:
				with open(file_path_bz2, "wb") as f:
					for chunk in resp.iter_content(chunk_size=8192):
						f.write(chunk)
				module_print("\n[FastDL Fallback] ", "cyan")
				module_print(f"Downloaded '{map_name}' successfully from '{base_url}'", "green")
				
				time.sleep(0.1) #hack
				
				try:
					file_path_extracted = DOWNLOAD_PATH / map_name
					with bz2.open(file_path_bz2, "rb") as f_in, open(file_path_extracted, "wb") as f_out:
						shutil.copyfileobj(f_in, f_out)
					module_print("\n[FastDL Fallback] ", "cyan")
					module_print(f"Extracted '{map_name}' to {DOWNLOAD_PATH}", "green")

					os.remove(file_path_bz2)

					downloaded_and_extracted = True
				except Exception as e:
					module_print("\n[FastDL Fallback] ", "cyan")
					module_print(f"Error extracting '{file_name_bz2}': {e}", "red")
					os.remove(file_path_bz2)
		except:
			continue

	if not downloaded_and_extracted:
		module_print("\n[FastDL Fallback] ", "cyan")
		module_print(f"'{map_name}' could not be downloaded/extracted from any FastDL services.", "red")

MISSING_MAP_PATTERN = re.compile(r"^Missing map maps/([^,]+),\s+disconnecting$")
MAP_DIFF_PATTERN = re.compile(r"^Your map \[maps/([^]]+)\] differs from the server's\.$")

def on_new_log(line, master=None):
	py_line = line.decode("utf-8") if isinstance(line, bytes) else str(line)

	match = MISSING_MAP_PATTERN.match(py_line)
	if match:
		map_name = match.group(1).strip()
		module_print("\n[FastDL Fallback] ", "cyan")
		module_print(f"The game is missing '{map_name}' and the server failed to provide it. Trying to download from other sources...", "red")
		threading.Thread(target=download_and_extract_map, args=(map_name,), daemon=True).start()
		return

	match_diff = MAP_DIFF_PATTERN.match(py_line)
	if match_diff:
		map_name = match_diff.group(1).strip()
		file_path = DOWNLOAD_PATH / map_name
		if file_path.exists():
			try:
				file_path.unlink()
				module_print("\n[FastDL Fallback] ", "cyan")
				module_print(f"Deleted mismatched map '{map_name}'. Trying to download correct version...", "red")
			except:
				pass
		threading.Thread(target=download_and_extract_map, args=(map_name,), daemon=True).start()