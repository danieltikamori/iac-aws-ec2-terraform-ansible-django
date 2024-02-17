cd /home/ec2-user
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo  python3 get-pip.py
sudo python3 -m pip install ansible
tee -a playbook.yml > /dev/null <<EOT
- hosts: localhost
  # become: yes
  tasks:
    - name: Installing python3, virtualenv
      yum:
        pkg:
        - python3
        - virtualenv
        update_cache: yes
      become: yes
    - name: Git Clone # Download the project
      ansible.builtin.git:
        repo: "https://github.com/guilhermeonrails/clientes-leo-api.git"
        dest: /home/ec2-user/web
        version: master
        force: yes # Force the clone to overwrite files if they already exist.
    - name: Installing dependencies with pip (Django and Django Rest)
      pip:
        virtualenv: /home/ec2-user/web/venv
        requirements: /home/ec2-user/web/setup/requirements.txt
    # - name: Verifying if the project already exists
    #   stat: # checking if the file exists in the directory
    #     path: /home/ec2-user/web/setup/settings.py
    #   register: project_exists # registering the result of the stat command, in this case True or False
    # - name: Starting the Project
    #   shell: '. /home/ec2-user/web/venv/bin/activate; django-admin startproject setup /home/ec2-user/web/'
    #   when: not project_exists.stat.exists # if the project doesn't exist, start the project
    #   # ignore_errors: yes # if the project already exists, ignore the error. By default, Ansible will fail the playbook if the project already exists. Use this parameter with caution, evaluate possible issues that may occur.
    - name: Changing the hosts in the settings.py file
      lineinfile:
        path: /home/ec2-user/web/setup/settings.py
        regexp: 'ALLOWED_HOSTS'
        line: 'ALLOWED_HOSTS = ["*"]'
        backrefs: yes
    - name: Configuring the database # In Django specifically, doesn't return error if we run twice, but it just try to run and finish the execution without errors.
      shell: '. /home/ec2-user/web/venv/bin/activate; python /home/ec2-user/web/manage.py migrate'
    - name: Loading initial data # Provided by the development team
      shell: '. /home/ec2-user/web/venv/bin/activate; python /home/ec2-user/web/manage.py loaddata clientes.json'
    - name: Starting the server
      shell: '. /home/ec2-user/web/venv/bin/activate; nohup python /home/ec2-user/web/manage.py runserver 0.0.0.0:8000 &'
EOT
ansible-playbook playbook.yml