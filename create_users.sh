#!/bin/bash

# Define the input file and log file
input_file="users.txt"
log_file="/var/log/user_management.log"
password_file="/var/secure/user_passwords.txt"

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Error: $input_file not found."
    exit 1
fi

# Create log file if it doesn't exist
sudo touch "$log_file"

# Create password file if it doesn't exist
if [[ ! -f "$password_file" ]]; then
    sudo touch "$password_file"
fi

# Function to generate a random password
generate_password() {
    local length="${1:-16}"  # Default length is 16 characters
    openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c"$length"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | sudo tee -a "$log_file" > /dev/null
}

# Arrays to store usernames and groups
declare -A user_groups
declare -A unique_groups
usernames=()

# Read the input file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Remove leading and trailing whitespace
    line=$(echo "$line" | xargs)
    
    # Split the line at the semicolon
    username=$(echo "$line" | cut -d ';' -f 1 | xargs)
    group_list=$(echo "$line" | cut -d ';' -f 2 | xargs)

    # Store username
    usernames+=("$username")

    # Store groups for each user
    user_groups["$username"]="$group_list"

    # Split groups by comma and store them in unique_groups
    IFS=',' read -ra group_array <<< "$group_list"
    for group in "${group_array[@]}"; do
        group=$(echo "$group" | xargs)
        unique_groups["$group"]=1  # Use group name as key to ensure uniqueness
    done

    # Create user and add to groups
    if sudo getent passwd "$username" &>/dev/null; then
        log_message "User '$username' already exists."
    else
        # Generate random password
        password=$(generate_password 12)  # Adjust password length as needed

        # Store password in file
        echo "$username:$password" | sudo tee -a "$password_file" > /dev/null

        if sudo useradd -m -p "$(openssl passwd -1 "$password")" "$username"; then
            log_message "User '$username' created successfully."

            # Add user to their respective groups
            for group in "${group_array[@]}"; do
                sudo usermod -aG "$group" "$username"
                log_message "User '$username' added to group '$group'."
            done

            # Set permissions for home directory
            sudo chmod 700 "/home/$username"
            sudo chown "$username":"$username" "/home/$username"
            log_message "Home directory permissions set for '$username'."
        else
            log_message "Failed to create user '$username'."
        fi
    fi

done < "$input_file"

# Create groups if they don't exist
for group in "${!unique_groups[@]}"; do
    if sudo getent group "$group" &>/dev/null; then
        log_message "Group '$group' already exists."
    else
        if sudo groupadd "$group"; then
            log_message "Group '$group' created successfully."
        else
            log_message "Failed to create group '$group'."
        fi
    fi
done
