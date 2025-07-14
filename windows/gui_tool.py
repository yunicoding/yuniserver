#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
YuniServer GUI 도구
Windows용 rclone 업로드/다운로드 GUI 프로그램
"""

import os
import sys
import subprocess
import threading
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext, simpledialog, filedialog
from datetime import datetime
import time
import json

class ServiceAccountDialog:
    def __init__(self, parent):
        self.result = None
        self.window = tk.Toplevel(parent)
        self.window.title("Google Service Account 설정")
        self.window.geometry("500x400")
        self.window.transient(parent)
        self.window.grab_set()
        
        # 메인 프레임
        main_frame = ttk.Frame(self.window, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # 설명
        ttk.Label(main_frame, text="Google Service Account JSON 키 설정", 
                 font=("맑은 고딕", 12, "bold")).pack(pady=(0, 10))
        
        ttk.Label(main_frame, text="Google Cloud Console에서 생성한 Service Account JSON 키가 필요합니다.",
                 wraplength=450).pack(pady=(0, 10))
        
        # 입력 방법 선택
        self.method_var = tk.StringVar(value="file")
        ttk.Label(main_frame, text="입력 방법 선택:").pack(anchor=tk.W)
        
        method_frame = ttk.Frame(main_frame)
        method_frame.pack(fill=tk.X, pady=(5, 10))
        
        ttk.Radiobutton(method_frame, text="파일 선택", variable=self.method_var, 
                       value="file").pack(side=tk.LEFT)
        ttk.Radiobutton(method_frame, text="직접 입력", variable=self.method_var, 
                       value="text").pack(side=tk.LEFT, padx=(20, 0))
        
        # 파일 선택 프레임
        self.file_frame = ttk.LabelFrame(main_frame, text="파일 선택", padding="10")
        self.file_frame.pack(fill=tk.X, pady=(0, 10))
        
        self.file_path_var = tk.StringVar()
        ttk.Entry(self.file_frame, textvariable=self.file_path_var, width=50).pack(side=tk.LEFT, padx=(0, 5))
        ttk.Button(self.file_frame, text="찾아보기", command=self.browse_file).pack(side=tk.LEFT)
        
        # 텍스트 입력 프레임
        self.text_frame = ttk.LabelFrame(main_frame, text="JSON 키 직접 입력", padding="10")
        self.text_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))
        
        self.json_text = scrolledtext.ScrolledText(self.text_frame, height=10, width=60)
        self.json_text.pack(fill=tk.BOTH, expand=True)
        
        # 버튼 프레임
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(button_frame, text="확인", command=self.ok_clicked).pack(side=tk.RIGHT, padx=(5, 0))
        ttk.Button(button_frame, text="취소", command=self.cancel_clicked).pack(side=tk.RIGHT)
        
        # 창을 화면 중앙에 배치
        self.window.update_idletasks()
        x = (self.window.winfo_screenwidth() // 2) - (self.window.winfo_width() // 2)
        y = (self.window.winfo_screenheight() // 2) - (self.window.winfo_height() // 2)
        self.window.geometry(f"+{x}+{y}")
    
    def browse_file(self):
        file_path = filedialog.askopenfilename(
            title="Service Account JSON 파일 선택",
            filetypes=[("JSON 파일", "*.json"), ("모든 파일", "*.*")]
        )
        if file_path:
            self.file_path_var.set(file_path)
    
    def ok_clicked(self):
        if self.method_var.get() == "file":
            file_path = self.file_path_var.get()
            if not file_path or not os.path.exists(file_path):
                messagebox.showerror("오류", "올바른 파일을 선택해주세요.")
                return
            
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    json_content = f.read()
                
                # JSON 유효성 확인
                json_data = json.loads(json_content)
                if json_data.get('type') != 'service_account':
                    messagebox.showerror("오류", "올바른 Service Account JSON 파일이 아닙니다.")
                    return
                
                self.result = ('file', file_path)
                
            except Exception as e:
                messagebox.showerror("오류", f"파일을 읽을 수 없습니다: {str(e)}")
                return
        else:
            json_content = self.json_text.get("1.0", tk.END).strip()
            if not json_content:
                messagebox.showerror("오류", "JSON 키를 입력해주세요.")
                return
            
            try:
                # JSON 유효성 확인
                json_data = json.loads(json_content)
                if json_data.get('type') != 'service_account':
                    messagebox.showerror("오류", "올바른 Service Account JSON이 아닙니다.")
                    return
                
                # 임시 파일에 저장
                temp_file = "temp-service-account.json"
                with open(temp_file, 'w', encoding='utf-8') as f:
                    f.write(json_content)
                
                self.result = ('text', temp_file)
                
            except json.JSONDecodeError:
                messagebox.showerror("오류", "올바른 JSON 형식이 아닙니다.")
                return
            except Exception as e:
                messagebox.showerror("오류", f"JSON 처리 중 오류: {str(e)}")
                return
        
        self.window.destroy()
    
    def cancel_clicked(self):
        self.result = None
        self.window.destroy()

class YuniServerGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("YuniServer 관리 도구")
        self.root.geometry("600x500")
        self.root.resizable(True, True)
        
        # 변수 설정
        self.is_running = False
        self.current_process = None
        
        # GUI 구성
        self.setup_gui()
        
        # 초기 상태 확인
        self.check_initial_status()
    
    def setup_gui(self):
        """GUI 구성"""
        # 메인 프레임
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=tk.W+tk.E+tk.N+tk.S)
        
        # 제목
        title_label = ttk.Label(main_frame, text="YuniServer 관리 도구", 
                               font=("맑은 고딕", 16, "bold"))
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))
        
        # 상태 표시
        status_frame = ttk.LabelFrame(main_frame, text="상태", padding="10")
        status_frame.grid(row=1, column=0, columnspan=2, sticky=tk.W+tk.E, pady=(0, 10))
        
        self.status_vars = {
            'rclone': tk.StringVar(value="확인 중..."),
            'google_drive': tk.StringVar(value="확인 중..."),
            'yuniserver': tk.StringVar(value="확인 중...")
        }
        
        ttk.Label(status_frame, text="Rclone 상태:").grid(row=0, column=0, sticky=tk.W)
        ttk.Label(status_frame, textvariable=self.status_vars['rclone']).grid(row=0, column=1, sticky=tk.W, padx=(10, 0))
        
        ttk.Label(status_frame, text="Google Drive:").grid(row=1, column=0, sticky=tk.W)
        ttk.Label(status_frame, textvariable=self.status_vars['google_drive']).grid(row=1, column=1, sticky=tk.W, padx=(10, 0))
        
        ttk.Label(status_frame, text="yuniserver 폴더:").grid(row=2, column=0, sticky=tk.W)
        ttk.Label(status_frame, textvariable=self.status_vars['yuniserver']).grid(row=2, column=1, sticky=tk.W, padx=(10, 0))
        
        # 버튼 프레임
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=2, column=0, columnspan=2, pady=10)
        
        self.setup_btn = ttk.Button(button_frame, text="초기 설정", command=self.run_setup)
        self.setup_btn.pack(side=tk.LEFT, padx=5)
        
        self.upload_btn = ttk.Button(button_frame, text="업로드", command=self.start_upload)
        self.upload_btn.pack(side=tk.LEFT, padx=5)
        
        self.download_btn = ttk.Button(button_frame, text="다운로드", command=self.start_download)
        self.download_btn.pack(side=tk.LEFT, padx=5)
        
        self.refresh_btn = ttk.Button(button_frame, text="상태 새로고침", command=self.check_initial_status)
        self.refresh_btn.pack(side=tk.LEFT, padx=5)
        
        # 진행률 표시
        progress_frame = ttk.LabelFrame(main_frame, text="진행률", padding="10")
        progress_frame.grid(row=3, column=0, columnspan=2, sticky=tk.W+tk.E, pady=(0, 10))
        
        self.progress_var = tk.DoubleVar()
        self.progress_bar = ttk.Progressbar(progress_frame, variable=self.progress_var, maximum=100)
        self.progress_bar.grid(row=0, column=0, sticky=tk.W+tk.E, pady=(0, 5))
        
        self.progress_text = tk.StringVar(value="대기 중...")
        ttk.Label(progress_frame, textvariable=self.progress_text).grid(row=1, column=0, sticky=tk.W)
        
        # 로그 창
        log_frame = ttk.LabelFrame(main_frame, text="로그", padding="10")
        log_frame.grid(row=4, column=0, columnspan=2, sticky=tk.W+tk.E+tk.N+tk.S, pady=(0, 10))
        
        self.log_text = scrolledtext.ScrolledText(log_frame, height=12, width=70)
        self.log_text.grid(row=0, column=0, sticky=tk.W+tk.E+tk.N+tk.S)
        
        # 그리드 가중치 설정
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(4, weight=1)
        progress_frame.columnconfigure(0, weight=1)
        log_frame.columnconfigure(0, weight=1)
        log_frame.rowconfigure(0, weight=1)
    
    def log(self, message):
        """로그 메시지 추가"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        self.log_text.insert(tk.END, log_message)
        self.log_text.see(tk.END)
        self.root.update_idletasks()
    
    def check_initial_status(self):
        """초기 상태 확인"""
        def check_status():
            # rclone 설치 확인
            try:
                result = subprocess.run(['rclone', 'version'], capture_output=True, text=True)
                if result.returncode == 0:
                    self.status_vars['rclone'].set("✓ 설치됨")
                else:
                    self.status_vars['rclone'].set("❌ 설치 안됨")
            except FileNotFoundError:
                self.status_vars['rclone'].set("❌ 설치 안됨")
            
            # Google Drive 연결 확인
            try:
                result = subprocess.run(['rclone', 'listremotes'], capture_output=True, text=True)
                if result.returncode == 0 and 'googledrive:' in result.stdout:
                    self.status_vars['google_drive'].set("✓ 연결됨")
                else:
                    self.status_vars['google_drive'].set("❌ 연결 안됨")
            except:
                self.status_vars['google_drive'].set("❌ 연결 안됨")
            
            # yuniserver 폴더 확인
            if os.path.exists('yuniserver'):
                self.status_vars['yuniserver'].set("✓ 존재함")
            else:
                self.status_vars['yuniserver'].set("❌ 존재하지 않음")
        
        threading.Thread(target=check_status, daemon=True).start()
    
    def run_setup(self):
        """초기 설정 실행"""
        if self.is_running:
            messagebox.showwarning("경고", "다른 작업이 진행 중입니다.")
            return
        
        # rclone이 이미 설정되어 있는지 확인
        try:
            result = subprocess.run(['rclone', 'listremotes'], capture_output=True, text=True)
            if result.returncode == 0 and 'googledrive:' in result.stdout:
                if messagebox.askyesno("확인", "Google Drive가 이미 설정되어 있습니다. 다시 설정하시겠습니까?"):
                    pass  # 계속 진행
                else:
                    return
        except:
            pass  # rclone이 없거나 오류가 발생한 경우 계속 진행
        
        # Service Account 설정 다이얼로그 먼저 표시
        dialog = ServiceAccountDialog(self.root)
        self.root.wait_window(dialog.window)
        
        if not dialog.result:
            messagebox.showinfo("취소", "설정이 취소되었습니다.")
            return
        
        method, file_path = dialog.result
        
        self.log("초기 설정 시작...")
        self.is_running = True
        self.progress_text.set("초기 설정 중...")
        self.progress_var.set(0)
        
        def setup():
            try:
                # rclone 설치 확인
                self.log("rclone 설치 확인 중...")
                try:
                    result = subprocess.run(['rclone', 'version'], capture_output=True, text=True)
                    if result.returncode != 0:
                        raise FileNotFoundError
                    self.log("✓ rclone이 이미 설치되어 있습니다.")
                except FileNotFoundError:
                    self.log("❌ rclone이 설치되지 않았습니다.")
                    self.log("rclone 자동 설치 중...")
                    
                    # rclone 설치
                    install_cmd = [
                        'powershell', '-Command',
                        'iwr https://rclone.org/install.ps1 -useb | iex'
                    ]
                    result = subprocess.run(install_cmd, capture_output=True, text=True)
                    
                    if result.returncode != 0:
                        self.log("❌ rclone 자동 설치 실패")
                        self.log("수동 설치: https://rclone.org/downloads/")
                        self.progress_text.set("설치 실패")
                        return
                    
                    self.log("✓ rclone 설치 완료")
                
                self.progress_var.set(40)
                self.log(f"✓ Service Account 키 설정 완료: {method}")
                
                # rclone 설정 디렉토리 생성
                config_dir = os.path.expanduser("~/.config/rclone")
                os.makedirs(config_dir, exist_ok=True)
                
                # rclone 설정 파일 생성
                self.log("rclone 설정 파일 생성 중...")
                config_file = os.path.join(config_dir, "rclone.conf")
                
                with open(config_file, 'w', encoding='utf-8') as f:
                    f.write("[googledrive]\n")
                    f.write("type = drive\n")
                    f.write(f"service_account_file = {file_path}\n")
                
                self.log("✓ rclone 설정 파일 생성 완료")
                self.progress_var.set(70)
                
                # Google Drive 연결 테스트
                self.log("Google Drive 연결 테스트 중...")
                result = subprocess.run(['rclone', 'lsf', 'googledrive:'], 
                                      capture_output=True, text=True, timeout=30)
                
                if result.returncode == 0:
                    self.log("✓ Google Drive 접근 권한 확인 완료")
                else:
                    self.log("⚠️ Google Drive 접근 권한을 확인하세요.")
                    self.log("Service Account 이메일을 Google Drive 폴더에 편집자로 추가했는지 확인하세요.")
                
                self.progress_var.set(85)
                
                # yuniserver 폴더 생성
                self.log("yuniserver 폴더 생성 중...")
                if not os.path.exists('yuniserver'):
                    os.makedirs('yuniserver')
                    self.log("✓ yuniserver 폴더 생성 완료")
                else:
                    self.log("✓ yuniserver 폴더가 이미 존재합니다.")
                
                # Google Drive에 yuniserver 폴더 생성
                subprocess.run(['rclone', 'mkdir', 'googledrive:yuniserver'], 
                             capture_output=True)
                self.log("✓ Google Drive 폴더 확인 완료")
                
                self.progress_var.set(100)
                self.log("🎉 설정 완료!")
                self.progress_text.set("설정 완료")
                self.check_initial_status()
                
            except Exception as e:
                self.log(f"설정 중 오류: {str(e)}")
                self.progress_text.set("설정 오류")
            finally:
                self.is_running = False
        
        threading.Thread(target=setup, daemon=True).start()
    
    def start_upload(self):
        """업로드 시작"""
        if self.is_running:
            messagebox.showwarning("경고", "다른 작업이 진행 중입니다.")
            return
        
        if not os.path.exists('yuniserver'):
            messagebox.showerror("오류", "yuniserver 폴더가 존재하지 않습니다.")
            return
        
        self.log("업로드 시작...")
        self.is_running = True
        self.progress_text.set("업로드 중...")
        self.progress_var.set(0)
        
        def upload():
            try:
                # upload.bat 실행
                process = subprocess.Popen(['upload.bat'], 
                                         stdout=subprocess.PIPE, 
                                         stderr=subprocess.STDOUT,
                                         text=True,
                                         cwd='.')
                
                if process.stdout:
                    for line in iter(process.stdout.readline, ''):
                        if line:
                            self.log(line.strip())
                            # 진행률 파싱 (간단한 버전)
                            if "%" in line:
                                try:
                                    percent = float(line.split("%")[0].split()[-1])
                                    self.progress_var.set(percent)
                                except:
                                    pass
                    
                    process.stdout.close()
                return_code = process.wait()
                
                if return_code == 0:
                    self.log("업로드 완료")
                    self.progress_text.set("업로드 완료")
                    self.progress_var.set(100)
                else:
                    self.log("업로드 실패")
                    self.progress_text.set("업로드 실패")
                    
            except Exception as e:
                self.log(f"업로드 중 오류: {str(e)}")
                self.progress_text.set("업로드 오류")
            finally:
                self.is_running = False
        
        threading.Thread(target=upload, daemon=True).start()
    
    def start_download(self):
        """다운로드 시작"""
        if self.is_running:
            messagebox.showwarning("경고", "다른 작업이 진행 중입니다.")
            return
        
        self.log("다운로드 시작...")
        self.is_running = True
        self.progress_text.set("다운로드 중...")
        self.progress_var.set(0)
        
        def download():
            try:
                # download.bat 실행
                process = subprocess.Popen(['download.bat'], 
                                         stdout=subprocess.PIPE, 
                                         stderr=subprocess.STDOUT,
                                         text=True,
                                         cwd='.')
                
                if process.stdout:
                    for line in iter(process.stdout.readline, ''):
                        if line:
                            self.log(line.strip())
                            # 진행률 파싱 (간단한 버전)
                            if "%" in line:
                                try:
                                    percent = float(line.split("%")[0].split()[-1])
                                    self.progress_var.set(percent)
                                except:
                                    pass
                    
                    process.stdout.close()
                return_code = process.wait()
                
                if return_code == 0:
                    self.log("다운로드 완료")
                    self.progress_text.set("다운로드 완료")
                    self.progress_var.set(100)
                    self.check_initial_status()
                else:
                    self.log("다운로드 실패")
                    self.progress_text.set("다운로드 실패")
                    
            except Exception as e:
                self.log(f"다운로드 중 오류: {str(e)}")
                self.progress_text.set("다운로드 오류")
            finally:
                self.is_running = False
        
        threading.Thread(target=download, daemon=True).start()
    
    def run(self):
        """프로그램 실행"""
        self.root.mainloop()

if __name__ == "__main__":
    # 현재 디렉토리가 windows 폴더인지 확인
    if os.path.basename(os.getcwd()) == 'windows':
        os.chdir('..')  # 상위 디렉토리로 이동
    
    app = YuniServerGUI()
    app.run() 