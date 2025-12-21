# Start Google Drive mount
alias gdrive-start='systemctl --user start gdrive.service'


alias gdrive-stop='systemctl --user stop gdrive.service'

# View recent logs
# journalctl --user -u gdrive.service -n 20
