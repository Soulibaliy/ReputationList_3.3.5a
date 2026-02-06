import os
import re
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
from pathlib import Path
from datetime import datetime
import shutil
import json

class ReputationMerger:
    def __init__(self, root):
        self.root = root
        self.root.title("WoW Reputation Merger")
        self.root.geometry("600x400")
        self.root.resizable(False, False)
        
        # Config file for saving path
        self.config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.json')
        
        # Path selection
        tk.Label(root, text="Путь до папки Account:", font=("Arial", 10)).pack(pady=(20, 5))
        
        path_frame = tk.Frame(root)
        path_frame.pack(pady=5, padx=20, fill=tk.X)
        
        self.path_entry = tk.Entry(path_frame, font=("Arial", 10), width=50)
        self.path_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        tk.Button(path_frame, text="Выбрать папку", command=self.select_folder, 
                  bg="#4CAF50", fg="white", font=("Arial", 9)).pack(side=tk.LEFT, padx=(5, 0))
        
        # Merge button
        tk.Button(root, text="Объединить данные", command=self.merge_data, 
                  bg="#2196F3", fg="white", font=("Arial", 11, "bold"), 
                  width=20, height=2).pack(pady=20)
        
        # Log area
        tk.Label(root, text="Лог операций:", font=("Arial", 10)).pack(pady=(10, 5))
        self.log_text = scrolledtext.ScrolledText(root, height=10, width=70, 
                                                   font=("Consolas", 9), state=tk.DISABLED)
        self.log_text.pack(pady=5, padx=20)
        
        # Load saved path
        self.load_config()
        
        # Save config on close
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        
    def load_config(self):
        """Load saved path from config"""
        try:
            if os.path.exists(self.config_file):
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                    saved_path = config.get('last_path', '')
                    if saved_path and os.path.exists(saved_path):
                        self.path_entry.insert(0, saved_path)
        except:
            pass
    
    def save_config(self):
        """Save current path to config"""
        try:
            path = self.path_entry.get()
            if path:
                with open(self.config_file, 'w', encoding='utf-8') as f:
                    json.dump({'last_path': path}, f)
        except:
            pass
    
    def on_closing(self):
        """Handle window close event"""
        self.save_config()
        self.root.destroy()
    
    def log(self, message):
        """Add message to log"""
        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, f"{message}\n")
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)
        self.root.update()
        
    def select_folder(self):
        """Open folder selection dialog"""
        folder = filedialog.askdirectory(title="Выберите папку Account")
        if folder:
            self.path_entry.delete(0, tk.END)
            self.path_entry.insert(0, folder)
            self.log(f"Выбрана папка: {folder}")
    
    def parse_lua_file(self, filepath):
        """Parse Lua file and extract reputation data"""
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract ReputationTrackerDB - сохраняем как есть
        tracker_db = None
        tracker_start = content.find('ReputationTrackerDB')
        if tracker_start != -1:
            # Находим начало таблицы
            brace_start = content.find('{', tracker_start)
            if brace_start != -1:
                # Ищем закрывающую скобку
                brace_count = 1
                pos = brace_start + 1
                while pos < len(content) and brace_count > 0:
                    if content[pos] == '{':
                        brace_count += 1
                    elif content[pos] == '}':
                        brace_count -= 1
                    pos += 1
                if brace_count == 0:
                    tracker_db = content[tracker_start:pos]
        
        # Extract ReputationGroupTrackerDB - сохраняем как есть
        group_tracker_db = None
        group_start = content.find('ReputationGroupTrackerDB')
        if group_start != -1:
            # Находим начало таблицы
            brace_start = content.find('{', group_start)
            if brace_start != -1:
                # Ищем закрывающую скобку
                brace_count = 1
                pos = brace_start + 1
                while pos < len(content) and brace_count > 0:
                    if content[pos] == '{':
                        brace_count += 1
                    elif content[pos] == '}':
                        brace_count -= 1
                    pos += 1
                if brace_count == 0:
                    group_tracker_db = content[group_start:pos]
        
        # Initialize data structure
        reputation_data = {
            'cardPositions': {},
            'autoNotify': True,
            'popupNotify': True,
            'colorLFG': True,
            'soundNotify': True,
            'uiMode': 'full',
            'filterMessages': False,
            'selfNotify': True,
            'initialized': True,
            'blockTrade': False,
            'blockInvites': False,
            'realms': {},
            'tracker_db': tracker_db,
            'group_tracker_db': group_tracker_db
        }
        
        # Extract cardPositions
        card_match = re.search(r'\["cardPositions"\]\s*=\s*\{([^}]*)\}', content)
        if card_match:
            card_content = card_match.group(1)
            y_match = re.search(r'\["y"\]\s*=\s*([-\d.]+)', card_content)
            x_match = re.search(r'\["x"\]\s*=\s*([-\d.]+)', card_content)
            if y_match and x_match:
                reputation_data['cardPositions'] = {
                    'y': float(y_match.group(1)),
                    'x': float(x_match.group(1))
                }
        
        # Extract boolean settings
        for field in ['autoNotify', 'popupNotify', 'colorLFG', 'soundNotify', 'filterMessages', 'selfNotify', 'blockTrade', 'blockInvites', 'initialized']:
            match = re.search(rf'\["{field}"\]\s*=\s*(true|false)', content)
            if match:
                reputation_data[field] = (match.group(1) == 'true')
        
        # Extract uiMode
        ui_match = re.search(r'\["uiMode"\]\s*=\s*"([^"]+)"', content)
        if ui_match:
            reputation_data['uiMode'] = ui_match.group(1)
        
        # Find realms section - ищем внутри ReputationListDB
        # Паттерн должен учитывать возможные запятые после списков
        realms_pattern = r'\["realms"\]\s*=\s*\{(.*?)\n\t\},?\s*\n\t\["(?:selfNotify|initialized|blockInvites|blockTrade)'
        realms_match = re.search(realms_pattern, content, re.DOTALL)
        
        if realms_match:
            realms_content = realms_match.group(1)
            # Extract realms
            reputation_data['realms'] = self.extract_realms(realms_content)
        
        return reputation_data
    
    def extract_realms(self, realms_content):
        """Extract realm data from realms section"""
        realms = {}
        
        # Find all realm entries
        realm_pattern = r'\["([^"]+)"\]\s*=\s*\{'
        potential_realms = list(re.finditer(realm_pattern, realms_content))
        
        if not potential_realms:
            return realms
        
        processed_positions = set()
        
        for i, realm_match in enumerate(potential_realms):
            realm_name = realm_match.group(1)
            start_pos = realm_match.end()
            
            if realm_match.start() in processed_positions:
                continue
            
            # Find the matching closing brace for this realm
            brace_count = 1
            pos = start_pos
            realm_end = -1
            
            while pos < len(realms_content) and brace_count > 0:
                if realms_content[pos] == '{':
                    brace_count += 1
                elif realms_content[pos] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        realm_end = pos
                        break
                pos += 1
            
            if realm_end == -1:
                continue
            
            realm_content = realms_content[start_pos:realm_end]
            
            # Check if this realm has expected list types
            has_whitelist = '["whitelist"]' in realm_content
            has_blacklist = '["blacklist"]' in realm_content
            has_notelist = '["notelist"]' in realm_content
            
            if has_whitelist or has_blacklist or has_notelist:
                # Mark positions as processed
                for j in range(i + 1, len(potential_realms)):
                    if potential_realms[j].start() < realm_end:
                        processed_positions.add(potential_realms[j].start())
                
                realm_data = {
                    'whitelist': {},
                    'blacklist': {},
                    'notelist': {}
                }
                
                # Extract each list type
                for list_type in ['whitelist', 'blacklist', 'notelist']:
                    # Найдём начало списка
                    list_start_pattern = rf'\["{list_type}"\]\s*=\s*\{{'
                    list_start_match = re.search(list_start_pattern, realm_content)
                    
                    if list_start_match:
                        start_pos = list_start_match.end()
                        
                        # Найдём закрывающую скобку списка, считая вложенность
                        brace_count = 1
                        pos = start_pos
                        list_end = -1
                        
                        while pos < len(realm_content) and brace_count > 0:
                            if realm_content[pos] == '{':
                                brace_count += 1
                            elif realm_content[pos] == '}':
                                brace_count -= 1
                                if brace_count == 0:
                                    list_end = pos
                                    break
                            pos += 1
                        
                        if list_end != -1:
                            list_content = realm_content[start_pos:list_end]
                            realm_data[list_type] = self.extract_players(list_content)
                
                realms[realm_name] = realm_data
        
        return realms
    
    def extract_players(self, list_content):
        """Extract player data from a list (whitelist/blacklist/notelist)"""
        players = {}
        
        # Find all player entries
        player_pattern = r'\["([^"]+)"\]\s*=\s*\{'
        potential_players = list(re.finditer(player_pattern, list_content))
        
        for player_match in potential_players:
            player_key = player_match.group(1).lower()
            start_pos = player_match.end()
            
            # Find matching closing brace
            brace_count = 1
            pos = start_pos
            player_end = -1
            
            while pos < len(list_content) and brace_count > 0:
                if list_content[pos] == '{':
                    brace_count += 1
                elif list_content[pos] == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        player_end = pos
                        break
                pos += 1
            
            if player_end == -1:
                continue
            
            player_content = list_content[start_pos:player_end]
            
            # Extract player fields
            player_data = {'key': player_key}
            
            # Extract string fields
            string_fields = ['note', 'addedDate', 'guid', 'class', 'race', 'name', 
                           'faction', 'addedBy', 'guild', 'armoryLink']
            for field in string_fields:
                match = re.search(rf'\["{field}"\]\s*=\s*"([^"]*)"', player_content)
                if match:
                    player_data[field] = match.group(1)
            
            # Extract numeric fields
            level_match = re.search(r'\["level"\]\s*=\s*(\d+)', player_content)
            if level_match:
                player_data['level'] = int(level_match.group(1))
            
            players[player_key] = player_data
        
        return players
    
    def merge_realm_lists(self, realm1, realm2):
        """Merge two realm data structures"""
        merged = {
            'whitelist': {},
            'blacklist': {},
            'notelist': {}
        }
        
        # Merge each list type
        for list_type in ['whitelist', 'blacklist', 'notelist']:
            list1 = realm1.get(list_type, {})
            list2 = realm2.get(list_type, {})
            
            # Start with all players from list1
            merged[list_type] = dict(list1)
            
            # Add players from list2
            for player_key, player_data in list2.items():
                if player_key not in merged[list_type]:
                    merged[list_type][player_key] = player_data
                # If player exists, keep the one with more recent date
                else:
                    existing_date = merged[list_type][player_key].get('addedDate', '')
                    new_date = player_data.get('addedDate', '')
                    if new_date > existing_date:
                        merged[list_type][player_key] = player_data
        
        return merged
    
    def format_player(self, player_data, indent_level):
        """Format player data for Lua output"""
        indent = '\t' * indent_level
        lines = []
        
        # Field order for consistent output
        field_order = ['note', 'addedDate', 'guid', 'class', 'armoryLink', 'race', 
                      'name', 'faction', 'addedBy', 'level', 'guild', 'key']
        
        for field in field_order:
            if field in player_data:
                value = player_data[field]
                if isinstance(value, str):
                    lines.append(f'{indent}["{field}"] = "{value}",')
                elif isinstance(value, (int, float)):
                    lines.append(f'{indent}["{field}"] = {value},')
        
        return '\n'.join(lines)
    
    def format_list(self, list_data, indent_level):
        """Format a list (whitelist/blacklist/notelist) for Lua output"""
        indent = '\t' * indent_level
        lines = []
        
        for player_key, player_data in sorted(list_data.items()):
            lines.append(f'{indent}["{player_key}"] = {{')
            lines.append(self.format_player(player_data, indent_level + 1))
            lines.append(f'{indent}}},')
        
        return '\n'.join(lines)
    
    def format_realm(self, realm_data, indent_level):
        """Format realm data for Lua output"""
        indent = '\t' * indent_level
        lines = ['{']
        
        # Format each list type
        for list_type in ['whitelist', 'notelist', 'blacklist']:
            list_data = realm_data.get(list_type, {})
            lines.append(f'{indent}["{list_type}"] = {{')
            if list_data:
                lines.append(self.format_list(list_data, indent_level + 1))
            lines.append(f'{indent}}},')
        
        lines.append('\t\t}')
        return '\n'.join(lines)
    
    def data_to_lua(self, global_data):
        """Convert merged data back to Lua format - preserving source file settings"""
        lines = []
        
        # ReputationListDB
        lines.append('ReputationListDB = {')
        
        # Card positions (from source)
        lines.append('\t["cardPositions"] = {')
        card_pos = global_data.get('cardPositions', {})
        if card_pos:
            lines.append(f'\t\t["y"] = {card_pos.get("y", 0)},')
            lines.append(f'\t\t["x"] = {card_pos.get("x", 0)},')
        lines.append('\t},')
        
        # Settings (from source)
        lines.append(f'\t["autoNotify"] = {"true" if global_data.get("autoNotify", True) else "false"},')
        lines.append(f'\t["popupNotify"] = {"true" if global_data.get("popupNotify", True) else "false"},')
        lines.append(f'\t["colorLFG"] = {"true" if global_data.get("colorLFG", True) else "false"},')
        lines.append(f'\t["soundNotify"] = {"true" if global_data.get("soundNotify", True) else "false"},')
        lines.append(f'\t["uiMode"] = "{global_data.get("uiMode", "full")}",')
        lines.append(f'\t["filterMessages"] = {"true" if global_data.get("filterMessages", False) else "false"},')
        
        # Merged realms data
        lines.append('\t["realms"] = {')
        for realm_name, realm_data in global_data.get('realms', {}).items():
            lines.append(f'\t\t["{realm_name}"] = {self.format_realm(realm_data, 3)},')
        lines.append('\t},')
        
        # More settings (from source)
        lines.append(f'\t["selfNotify"] = {"true" if global_data.get("selfNotify", True) else "false"},')
        lines.append(f'\t["blockInvites"] = {"true" if global_data.get("blockInvites", False) else "false"},')
        lines.append(f'\t["blockTrade"] = {"true" if global_data.get("blockTrade", False) else "false"},')
        lines.append(f'\t["initialized"] = {"true" if global_data.get("initialized", True) else "false"},')
        
        lines.append('}')
        
        # Add tracker DBs from source if available
        if global_data.get('tracker_db'):
            lines.append(global_data['tracker_db'])
        else:
            lines.append('ReputationTrackerDB = {')
            lines.append('\t["minimapAngle"] = 180.0,')
            lines.append('}')
        
        if global_data.get('group_tracker_db'):
            lines.append(global_data['group_tracker_db'])
        
        return '\n'.join(lines) + '\n'
    
    def merge_data(self):
        """Main merge function"""
        account_path = self.path_entry.get()
        
        if not account_path:
            messagebox.showerror("Ошибка", "Пожалуйста, выберите папку Account")
            return
        
        if not os.path.exists(account_path):
            messagebox.showerror("Ошибка", f"Путь не существует: {account_path}")
            return
        
        self.log_text.config(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state=tk.DISABLED)
        
        self.log("=== Начало объединения ===")
        self.log(f"Путь: {account_path}")
        
        # Find all account folders
        account_folders = [f for f in os.listdir(account_path) 
                          if os.path.isdir(os.path.join(account_path, f))]
        
        self.log(f"Найдено аккаунтов: {len(account_folders)}")
        
        # Collect all account paths
        all_accounts = []
        reputation_files = []
        default_settings = None
        
        for account in account_folders:
            saved_vars_dir = os.path.join(account_path, account, "SavedVariables")
            rep_file = os.path.join(saved_vars_dir, "reputation.lua")
            
            all_accounts.append((account, saved_vars_dir))
            
            if os.path.exists(rep_file):
                reputation_files.append((account, rep_file))
                self.log(f"  ✓ {account}: reputation.lua найден")
                # Save first file settings as default for new accounts
                if default_settings is None:
                    default_settings = self.parse_lua_file(rep_file)
            else:
                self.log(f"  ✗ {account}: reputation.lua не найден (будет создан)")
        
        if not reputation_files:
            messagebox.showwarning("Предупреждение", "Не найдено файлов reputation.lua")
            return
        
        # Merge all realm lists from all accounts
        self.log("\n=== Объединение списков игроков ===")
        merged_realms = {}
        
        for account, file_path in reputation_files:
            self.log(f"Обработка {account}...")
            
            try:
                data = self.parse_lua_file(file_path)
                
                # Debug info
                realms_found = list(data.get('realms', {}).keys())
                if realms_found:
                    self.log(f"  Найдены realms: {realms_found}")
                    for realm_name, realm_data in data.get('realms', {}).items():
                        wl = len(realm_data.get('whitelist', {}))
                        bl = len(realm_data.get('blacklist', {}))
                        nl = len(realm_data.get('notelist', {}))
                        self.log(f"    {realm_name}: WL={wl}, BL={bl}, NL={nl}")
                else:
                    self.log(f"  ⚠ Realms не найдены!")
                
                # Merge realms
                for realm_name, realm_data in data.get('realms', {}).items():
                    if realm_name not in merged_realms:
                        merged_realms[realm_name] = realm_data
                    else:
                        merged_realms[realm_name] = self.merge_realm_lists(
                            merged_realms[realm_name],
                            realm_data
                        )
                
                self.log(f"  ✓ Списки из {account} обработаны")
                
            except Exception as e:
                self.log(f"  ✗ Ошибка при обработке {account}: {str(e)}")
                import traceback
                self.log(traceback.format_exc())
        
        # Write merged data to ALL accounts, preserving individual settings
        self.log("\n=== Запись объединенных данных ===")
        
        backup_count = 0
        write_count = 0
        created_count = 0
        
        for account, saved_vars_dir in all_accounts:
            try:
                # Ensure SavedVariables directory exists
                if not os.path.exists(saved_vars_dir):
                    os.makedirs(saved_vars_dir)
                    self.log(f"  + Создана папка SavedVariables для {account}")
                
                file_path = os.path.join(saved_vars_dir, "reputation.lua")
                
                # Load existing settings or use defaults
                if os.path.exists(file_path):
                    # Keep original settings, only update realms
                    account_data = self.parse_lua_file(file_path)
                    account_data['realms'] = merged_realms
                    
                    backup_path = file_path + ".backup"
                    shutil.copy2(file_path, backup_path)
                    backup_count += 1
                    action = "обновлен (настройки сохранены)"
                else:
                    # Use default settings for new files
                    account_data = dict(default_settings)
                    account_data['realms'] = merged_realms
                    created_count += 1
                    action = "создан"
                
                # Generate Lua output with account's own settings
                lua_output = self.data_to_lua(account_data)
                
                # Write merged data
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(lua_output)
                write_count += 1
                
                self.log(f"  ✓ {account}: {action}")
                
            except Exception as e:
                self.log(f"  ✗ {account}: ошибка записи - {str(e)}")
                import traceback
                self.log(traceback.format_exc())
        
        self.log("\n=== Завершено ===")
        self.log(f"Создано новых файлов: {created_count}")
        self.log(f"Создано backup файлов: {backup_count}")
        self.log(f"Всего обновлено файлов: {write_count}")
        
        # Show summary
        total_players = 0
        for realm_data in merged_realms.values():
            total_players += len(realm_data.get('whitelist', {}))
            total_players += len(realm_data.get('blacklist', {}))
            total_players += len(realm_data.get('notelist', {}))
        
        self.log(f"Всего записей игроков: {total_players}")
        
        messagebox.showinfo("Успешно", 
                           f"Объединение завершено!\n\n"
                           f"Обработано аккаунтов: {len(all_accounts)}\n"
                           f"Создано новых файлов: {created_count}\n"
                           f"Обновлено файлов: {backup_count}\n"
                           f"Всего записей: {total_players}\n\n"
                           f"Каждый аккаунт сохранил свои настройки\n"
                           f"Backup файлы созданы с расширением .backup")

if __name__ == "__main__":
    root = tk.Tk()
    app = ReputationMerger(root)
    root.mainloop()
