A Bash Script Automation for User and Group Management in Linux 

# User Management Script (create_users.sh)

This repository contains a Bash script (`create_users.sh`) designed for managing user creation and group assignment on a Linux system, specifically tailored for new developers joining the company. Below are the details and requirements for understanding and using this script effectively.

## Overview

As a SysOps engineer, the script automates the following tasks based on input from a text file (`users.txt`):
- Creation of users specified in the file
- Assignment of users to their respective groups
- Setup of home directories with appropriate permissions
- Generation of random passwords for each user
- Logging of all actions to `/var/log/user_management.log`
- Secure storage of generated passwords in `/var/secure/user_passwords.txt`

## Usage

### Running the Script

To execute the script, run the following command on an Ubuntu machine:
Ensure the script is Executable:
chmod +x create_users.sh

Run the Script with Sudo:
sudo ./create_users.sh

Replace <users.txt> with the actual name of your text file containing usernames and groups in the format username;groups.

File Structure

create_users.sh: The main Bash script responsible for user management.
README.md: This file, providing an overview of the script and its usage.
/var/log/user_management.log: Log file capturing all script actions.
/var/secure/user_passwords.txt: Securely stores user passwords.

Technical Article

For a detailed explanation of the script's implementation and reasoning, refer to the technical article associated with this project. The article includes clear steps, error handling strategies. check the article here https://dev.to/peewells/bash-script-automation-for-user-and-group-management-in-linux-54c6

