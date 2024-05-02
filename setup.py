import os


def main():
    this_file    = os.path.abspath(__file__)
    project_path = os.path.dirname(this_file)
    venv         = os.path.join(project_path, '.venv')

    if os.name == 'nt':
        venv_python  = os.path.join(project_path, '.venv', 'Scripts', 'python.exe')
        venv_pip     = os.path.join(project_path, '.venv', 'Scripts', 'pip.exe')
    else:
        venv_python  = os.path.join(project_path, '.venv', 'bin', 'python3')
        venv_pip     = os.path.join(project_path, '.venv', 'bin', 'pip3')

    if not os.path.exists(venv): 
        # Create venv
        os.chdir(project_path)
        print(f'Installing virtual environment in "{project_path}"')
        if os.name == 'nt':
            os.system(f'python -m venv .venv')
        else:
            os.system(f'python3 -m venv .venv')

    # Install requirements
    print(f'Installing packages from requirements.txt')
    os.system(f'"{venv_python}" -m pip install --upgrade pip')
    os.system(f'"{venv_pip}" install wheel')
    os.system(f'"{venv_pip}" install -r requirements.txt')

if __name__ == '__main__':
    main()