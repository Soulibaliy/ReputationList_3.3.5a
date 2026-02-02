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
        
        # Extract tracker data
        tracker_match = re.search(r'ReputationTrackerDB\s*=\s*\{[^}]*\["minimapAngle"\]\s*=\s*([-\d.]+)', content)
        tracker_angle = float(tracker_match.group(1)) if tracker_match else 180.0
        
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
            'realms': {}
        }
        
        # Extract cardPositions
        card_match = re.search(r'\["cardPositions"\]\s*=\s*\{([^}]*)\}', content)
        if card_match:
            card_content = card_match.group(1)
            y_match = re.search(r'\["y"\]\s*=\s*([\d.]+)', card_content)
            x_match = re.search(r'\["x"\]\s*=\s*([\d.]+)', card_content)
            if y_match and x_match:
                reputation_data['cardPositions'] = {
                    'y': float(y_match.group(1)),
                    'x': float(x_match.group(1))
                }
        
        # Extract boolean settings
        for field in ['autoNotify', 'popupNotify', 'colorLFG', 'soundNotify', 'filterMessages', 'selfNotify', 'blockTrade', 'blockInvites']:
            match = re.search(rf'\["{field}"\]\s*=\s*(true|false)', content)
            if match:
                reputation_data[field] = (match.group(1) == 'true')
        
        # Extract uiMode
        ui_match = re.search(r'\["uiMode"\]\s*=\s*"([^"]+)"', content)
        if ui_match:
            reputation_data['uiMode'] = ui_match.group(1)
        
        # Find realms section
        realms_pattern = r'\["realms"\]\s*=\s*\{(.*?)\},\s*\["(?:selfNotify|initialized)'
        realms_match = re.search(realms_pattern, content, re.DOTALL)
        
        if not realms_match:
            return reputation_data, tracker_angle
        
        realms_content = realms_match.group(1)
        
        # Extract realms
        reputation_data['realms'] = self.extract_realms(realms_content)
        
        return reputation_data, tracker_angle
    
    def extract_realms(self, realms_content):
        """Extract realm data from realms section"""
        realms = {}
        
        # Find all realm entries - need to be more careful about nested structures
        # Pattern: find ["realm_name"] = { and then find its matching closing brace
        
        # First, let's find all potential realm starts
        realm_pattern = r'\["([^"]+)"\]\s*=\s*\{'
        potential_realms = list(re.finditer(realm_pattern, realms_content))
        
        if not potential_realms:
            return realms
        
        processed_positions = set()  # Track which positions we've already processed
        
        for i, realm_match in enumerate(potential_realms):
            realm_name = realm_match.group(1)
            start_pos = realm_match.end()
            
            # Skip if we've already processed this position as part of another realm
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
            
            # Check if this realm has ALL THREE expected list types (more strict check)
            # A real realm MUST have whitelist, blacklist, AND notelist
            has_whitelist = bool(re.search(r'\["whitelist"\]\s*=\s*\{', realm_content))
            has_blacklist = bool(re.search(r'\["blacklist"\]\s*=\s*\{', realm_content))
            has_notelist = bool(re.search(r'\["notelist"\]\s*=\s*\{', realm_content))
            
            if not (has_whitelist and has_blacklist and has_notelist):
                continue
            
            # Mark all positions within this realm as processed
            for pos in range(realm_match.start(), realm_end + 1):
                processed_positions.add(pos)
            
            # Initialize realm structure
            realms[realm_name] = {
                'whitelist': {},
                'blacklist': {},
                'notelist': {}
            }
            
            # Extract each list type
            for list_type in ['whitelist', 'blacklist', 'notelist']:
                list_pattern = rf'\["{list_type}"\]\s*=\s*\{{'
                list_match = re.search(list_pattern, realm_content)
                
                if not list_match:
                    continue
                
                list_start = list_match.end()
                
                # Find matching closing brace for this list
                brace_count = 1
                pos = list_start
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
                
                if list_end == -1:
                    continue
                
                list_content = realm_content[list_start:list_end]
                
                # Extract player entries
                player_pattern = r'\["([^"]+)"\]\s*=\s*\{'
                players = list(re.finditer(player_pattern, list_content))
                
                for p_idx, player_match in enumerate(players):
                    player_key = player_match.group(1)
                    p_end = player_match.end()
                    
                    # Find matching closing brace for player
                    brace_count = 1
                    pos = p_end
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
                    
                    player_content = list_content[p_end:player_end]
                    
                    player_data = {}
                    
                    # Extract string fields
                    for field_match in re.finditer(r'\["([^"]+)"\]\s*=\s*"([^"]*)"', player_content):
                        player_data[field_match.group(1)] = field_match.group(2)
                    
                    # Extract numeric fields
                    for field_match in re.finditer(r'\["([^"]+)"\]\s*=\s*(\d+)', player_content):
                        player_data[field_match.group(1)] = int(field_match.group(2))
                    
                    realms[realm_name][list_type][player_key] = player_data
        
        return realms
    
    def parse_date(self, date_str):
        """Parse date string to datetime object"""
        try:
            return datetime.strptime(date_str, "%d.%m.%Y %H:%M")
        except:
            return datetime.min
    
    def merge_player_data(self, existing, new):
        """
        Merge two player records:
        - Берем запись с более поздней датой
        - Дополняем отсутствующие поля из старой записи
        """
        existing_date = self.parse_date(existing.get('addedDate', ''))
        new_date = self.parse_date(new.get('addedDate', ''))
        
        # Выбираем более свежую запись как базовую
        if new_date > existing_date:
            base_record = dict(new)
            supplement_record = existing
        else:
            base_record = dict(existing)
            supplement_record = new
        
        # Дополняем отсутствующие поля из дополнительной записи
        for field, value in supplement_record.items():
            if field not in base_record or not base_record[field]:
                base_record[field] = value
        
        return base_record
    
    def merge_realm_lists(self, realm1, realm2):
        """
        Объединяет все списки realm'а с учетом переноса между списками.
        Игрок помещается в тот список, где его запись новее.
        """
        # Собираем всех игроков из всех списков обоих realm'ов
        all_players = {}  # {identifier: [(list_type, player_data), ...]}
        name_to_guid = {}  # {normalized_name: guid} для связи записей без GUID
        
        def add_player(list_type, player_key, player_data, realm_idx):
            """Добавляет игрока в общий пул"""
            guid = player_data.get('guid', '')
            name = player_data.get('name', '').lower()
            
            # Если есть GUID, сохраняем связь имя -> GUID
            if guid and name:
                if name in name_to_guid:
                    # Если для этого имени уже есть GUID, используем существующий
                    # (на случай если это разные записи одного игрока)
                    pass
                else:
                    name_to_guid[name] = guid
            
            # Создаем идентификатор
            if guid:
                identifier = guid
            elif name:
                # Проверяем, есть ли уже GUID для этого имени
                if name in name_to_guid:
                    identifier = name_to_guid[name]
                else:
                    identifier = f"name:{name}"
            else:
                # Нет ни GUID, ни имени - используем ключ
                identifier = f"key:{player_key}"
            
            if identifier not in all_players:
                all_players[identifier] = []
            
            all_players[identifier].append({
                'list_type': list_type,
                'player_key': player_key,
                'player_data': player_data,
                'realm_idx': realm_idx
            })
        
        # ПЕРВЫЙ ПРОХОД: собираем все GUID и связываем с именами
        for realm_data in [realm1, realm2]:
            for list_type in ['blacklist', 'whitelist', 'notelist']:
                for player_key, player_data in realm_data.get(list_type, {}).items():
                    guid = player_data.get('guid', '')
                    name = player_data.get('name', '').lower()
                    if guid and name:
                        name_to_guid[name] = guid
        
        # ВТОРОЙ ПРОХОД: собираем игроков с учетом связей
        for list_type in ['blacklist', 'whitelist', 'notelist']:
            for player_key, player_data in realm1.get(list_type, {}).items():
                add_player(list_type, player_key, player_data, 1)
        
        for list_type in ['blacklist', 'whitelist', 'notelist']:
            for player_key, player_data in realm2.get(list_type, {}).items():
                add_player(list_type, player_key, player_data, 2)
        
        # Результирующие списки
        result_realm = {
            'blacklist': {},
            'whitelist': {},
            'notelist': {}
        }
        
        # Обрабатываем каждого уникального игрока
        for identifier, entries in all_players.items():
            if len(entries) == 1:
                # Игрок найден только в одном месте
                entry = entries[0]
                result_realm[entry['list_type']][entry['player_key']] = entry['player_data']
            else:
                # Игрок найден в нескольких местах - нужно объединить
                # Находим запись с самой поздней датой
                newest_entry = None
                newest_date = datetime.min
                
                for entry in entries:
                    entry_date = self.parse_date(entry['player_data'].get('addedDate', ''))
                    if entry_date > newest_date:
                        newest_date = entry_date
                        newest_entry = entry
                
                # Объединяем данные из всех записей
                merged_data = dict(newest_entry['player_data'])
                
                # Дополняем отсутствующие поля из других записей
                for entry in entries:
                    if entry is not newest_entry:
                        for field, value in entry['player_data'].items():
                            if field not in merged_data or not merged_data[field]:
                                merged_data[field] = value
                
                # Помещаем в список из самой свежей записи
                target_list = newest_entry['list_type']
                player_key = newest_entry['player_key']
                
                result_realm[target_list][player_key] = merged_data
        
        return result_realm
    
    def format_player_entry(self, player_data, indent=0):
        """Format a single player entry"""
        lines = []
        tab = '\t' * indent
        
        # Order of fields to match original format
        field_order = ['note', 'addedDate', 'guid', 'class', 'race', 'name', 'faction', 'key', 'level', 'guild', 'addedBy']
        
        for field in field_order:
            if field in player_data:
                value = player_data[field]
                if isinstance(value, str):
                    lines.append(f'{tab}["{field}"] = "{value}",')
                elif isinstance(value, int):
                    lines.append(f'{tab}["{field}"] = {value},')
        
        return '\n'.join(lines)
    
    def format_realm(self, realm_data, indent=0):
        """Format a complete realm"""
        lines = []
        tab = '\t' * indent
        
        lines.append('{')
        
        # Format lists in order
        for list_type in ['whitelist', 'blacklist', 'notelist']:
            if list_type in realm_data:
                lines.append(tab + '["' + list_type + '"] = {')
                
                for player_key, player_data in realm_data[list_type].items():
                    lines.append(tab + '\t["' + player_key + '"] = {')
                    lines.append(self.format_player_entry(player_data, indent + 2))
                    lines.append(tab + '\t},')
                
                lines.append(tab + '},')
        
        if len(tab) > 0:
            lines.append(tab[:-1] + '}')
        else:
            lines.append('}')
        
        return '\n'.join(lines)
    
    def data_to_lua(self, data, tracker_angle):
        """Convert merged data back to Lua format"""
        lines = []
        
        lines.append('ReputationListDB = {')
        
        # Global data section
        global_data = data
        
        # Basic settings
        lines.append(f'\t["autoNotify"] = {"true" if global_data.get("autoNotify", True) else "false"},')
        lines.append(f'\t["popupNotify"] = {"true" if global_data.get("popupNotify", True) else "false"},')
        lines.append(f'\t["colorLFG"] = {"true" if global_data.get("colorLFG", True) else "false"},')
        lines.append(f'\t["soundNotify"] = {"true" if global_data.get("soundNotify", True) else "false"},')
        lines.append(f'\t["uiMode"] = "{global_data.get("uiMode", "full")}",')
        lines.append(f'\t["filterMessages"] = {"true" if global_data.get("filterMessages", False) else "false"},')
        lines.append(f'\t["selfNotify"] = {"true" if global_data.get("selfNotify", True) else "false"},')
        lines.append(f'\t["initialized"] = {"true" if global_data.get("initialized", True) else "false"},')
        lines.append(f'\t["blockTrade"] = {"true" if global_data.get("blockTrade", False) else "false"},')
        lines.append(f'\t["blockInvites"] = {"true" if global_data.get("blockInvites", False) else "false"},')
        
        # Card positions
        lines.append('\t["cardPositions"] = {')
        card_pos = global_data.get('cardPositions', {})
        if card_pos:
            lines.append(f'\t\t["y"] = {card_pos.get("y", 0)},')
            lines.append(f'\t\t["x"] = {card_pos.get("x", 0)},')
        lines.append('\t},')
        
        # GUID map (if exists)
        if global_data.get('guidMap'):
            lines.append('\t["guidMap"] = {')
            for guid, guid_data in global_data['guidMap'].items():
                lines.append('\t\t["' + guid + '"] = {')
                if 'realm' in guid_data:
                    lines.append('\t\t\t["realm"] = "' + guid_data["realm"] + '",')
                if 'key' in guid_data:
                    lines.append('\t\t\t["key"] = "' + guid_data["key"] + '",')
                if 'list' in guid_data:
                    lines.append('\t\t\t["list"] = "' + guid_data["list"] + '",')
                lines.append('\t\t},')
            lines.append('\t},')
        
        # Stats
        if global_data.get('stats'):
            lines.append('\t["stats"] = {')
            lines.append(f'\t\t["totalPlayers"] = {global_data["stats"].get("totalPlayers", 0)},')
            lines.append('\t},')
        
        # Migrated
        lines.append(f'\t["migrated"] = {"true" if global_data.get("migrated", True) else "false"},')
        
        # Realms
        lines.append('\t["realms"] = {')
        
        for realm_name, realm_data in global_data.get('realms', {}).items():
            lines.append(f'\t\t["{realm_name}"] = {self.format_realm(realm_data, 3)},')
        
        lines.append('\t},')
        lines.append('}')
        
        # Tracker
        lines.append('ReputationTrackerDB = {')
        lines.append(f'\t["minimapAngle"] = {tracker_angle},')
        lines.append('}')
        
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
        
        # Collect all account paths (both with and without reputation.lua)
        all_accounts = []
        reputation_files = []
        
        for account in account_folders:
            saved_vars_dir = os.path.join(account_path, account, "SavedVariables")
            rep_file = os.path.join(saved_vars_dir, "reputation.lua")
            
            # Add to all accounts list
            all_accounts.append((account, saved_vars_dir))
            
            if os.path.exists(rep_file):
                reputation_files.append((account, rep_file))
                self.log(f"  ✓ {account}: reputation.lua найден")
            else:
                self.log(f"  ✗ {account}: reputation.lua не найден (будет создан)")
        
        if not reputation_files:
            messagebox.showwarning("Предупреждение", "Не найдено файлов reputation.lua")
            return
        
        # Merge all data
        merged_data = None
        tracker_angle = 180.0
        
        for account, file_path in reputation_files:
            self.log(f"Обработка {account}...")
            
            try:
                data, angle = self.parse_lua_file(file_path)
                tracker_angle = angle  # Use last found angle
                
                if merged_data is None:
                    merged_data = data
                else:
                    # Merge realms using new logic
                    for realm_name, realm_data in data.get('realms', {}).items():
                        if realm_name not in merged_data['realms']:
                            merged_data['realms'][realm_name] = realm_data
                        else:
                            # Merge with cross-list logic
                            merged_data['realms'][realm_name] = self.merge_realm_lists(
                                merged_data['realms'][realm_name],
                                realm_data
                            )
                
                self.log(f"  ✓ Данные из {account} обработаны")
                
            except Exception as e:
                self.log(f"  ✗ Ошибка при обработке {account}: {str(e)}")
                import traceback
                self.log(traceback.format_exc())
        
        # Generate Lua output
        lua_output = self.data_to_lua(merged_data, tracker_angle)
        
        # Write merged data to ALL accounts (including those without reputation.lua)
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
                
                # Create backup if file exists
                if os.path.exists(file_path):
                    backup_path = file_path + ".backup"
                    shutil.copy2(file_path, backup_path)
                    backup_count += 1
                    action = "обновлен"
                else:
                    created_count += 1
                    action = "создан"
                
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
        for realm_data in merged_data.get('realms', {}).values():
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
                           f"Backup файлы созданы с расширением .backup")

if __name__ == "__main__":
    root = tk.Tk()
    app = ReputationMerger(root)
    root.mainloop()
