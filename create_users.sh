#!/bin/bash

# Log file and secure passwords file
LOGFILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the log file and secure passwords file exist with correct permissions
sudo mkdir -p /var/secure
sudo touch "$PASSWORD_FILE"
sudo chmod 600 "$PASSWORD_FILE"
sudo touch "$LOGFILE"
sudo chmod 600 "$LOGFILE"

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
    echo "openssl is required but not installed. Please install it and try again." >&2
    exit 1
fi

# Read the input file line by line
while IFS=';' read -r username groups; do
    # Remove any leading or trailing whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Create a personal group with the same name as the username
    if ! getent group "$username" > /dev/null 2>&1; then
        if sudo groupadd "$username"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Group '$username' created." >> "$LOGFILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Error creating group '$username'." >> "$LOGFILE"
            continue
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Group '$username' already exists." >> "$LOGFILE"
    fi

    # Create the user if it does not exist
    if ! id -u "$username" > /dev/null 2>&1; then
        if sudo useradd -m -s /bin/bash -g "$username" "$username"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' created." >> "$LOGFILE"

            # Generate a random password for the user
            password=$(generate_password)
            echo "$username:$password" | sudo chpasswd
            echo "$username:$password" | sudo tee -a "$PASSWORD_FILE" > /dev/null

            # Set ownership and permissions for the user's home directory
            sudo chown "$username":"$username" "/home/$username"
            sudo chmod 700 "/home/$username"

            echo "$(date '+%Y-%m-%d %H:%M:%S') - Password for '$username' set and stored securely." >> "$LOGFILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Error creating user '$username'." >> "$LOGFILE"
            continue
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' already exists." >> "$LOGFILE"
    fi

    # Add user to additional groups
    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        if ! getent group "$group" > /dev/null 2>&1; then
            if sudo groupadd "$group"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Group '$group' created." >> "$LOGFILE"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Error creating group '$group'." >> "$LOGFILE"
                continue
            fi
        fi
        if sudo usermod -aG "$group" "$username"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - User '$username' added to group '$group'." >> "$LOGFILE"
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Error adding user '$username' to group '$group'." >> "$LOGFILE"
        fi
    done
done < "$1"

echo "User creation process completed."
exit 0
