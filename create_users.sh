#!/bin/bash

# Log file location
LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"
USER_LIST_FILE="users.txt"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

echo "Script started."

# Check if the user list file exists
if [ ! -f "$USER_LIST_FILE" ]; then
    echo "User list file not found: $USER_LIST_FILE"
    exit 1
fi

echo "Processing user list file: $USER_LIST_FILE"

# Create the secure directory if it does not exist
mkdir -p /var/secure
chmod 700 /var/secure

echo "Secure directory created."

# Empty the password file if it exists
> "$PASSWORD_FILE"

echo "Password file emptied."

# Ensure the log file has the right permissions
touch "$LOGFILE"
chmod 600 "$LOGFILE"

echo "Log file permissions set."

# Process the user list file
while IFS=';' read -r username groups; do
    username=$(echo "$username" | tr -d '[:space:]')
    groups=$(echo "$groups" | tr -d '[:space:]')

    echo "Processing user: $username"

    # Check if user already exists
    if id "$username" &>/dev/null; then
        log_message "User $username already exists."
    else
        # Create the user with a home directory and a personal group
        useradd -m -s /bin/bash -U "$username"
        if [ $? -eq 0 ]; then
            log_message "User $username created successfully."
        else
            log_message "Failed to create user $username."
            continue
        fi

        # Generate a random password
        password=$(openssl rand -base64 12)

        # Set the user's password
        echo "$username:$password" | chpasswd

        # Store the password securely
        echo "$username,$password" >> "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"

        # Log password storage
        if [ $? -eq 0 ]; then
            log_message "Password for $username stored securely."
        else
            log_message "Failed to store password for $username."
        fi
    fi

    # Add the user to additional groups
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
        group=$(echo "$group" | tr -d '[:space:]')
        if [ -z "$group" ]; then
            continue
        fi

        # Check if the group exists, if not, create it
        if ! getent group "$group" &>/dev/null; then
            groupadd "$group"
            if [ $? -eq 0 ]; then
                log_message "Group $group created."
            else
                log_message "Failed to create group $group."
                continue
            fi
        fi

        usermod -aG "$group" "$username"
        if [ $? -eq 0 ]; then
            log_message "User $username added to group $group."
        else
            log_message "Failed to add user $username to group $group."
        fi
    done
done < "$USER_LIST_FILE"

log_message "User creation process completed."

echo "Script completed."

exit 0
