# AIS Middleware Installer

This repository contains the installer and binary for the Alert Integration Service (AIS), which allows forwarding alerts from ThousandEyes to downstream services like ServiceNow or Alerts API endpoints.

---

## 📦 Contents

- `ais-middleware`: Precompiled binary (for Linux x86_64)
- `installation_script.sh`: Interactive installer that configures and deploys AIS

---

## 🚀 Installation Instructions

### 1. Clone this repository

```bash
git clone https://github.com/<your-org-or-user>/ais-installer.git
cd ais-v3-installer
```

---

### 2. Make sure the installer is executable

```bash
chmod +x installation_script.sh
```

---

### 3. Run the installer

```bash
./installation_script.sh
```

You will be prompted to:

- Choose a directory for installation (leave blank to use the current folder)
- Select integration types (`alertsapi` or `servicenow`)
- Enter your ThousandEyes token and account group info
- Confirm configuration

The installer will:
- Copy the binary to your install directory
- Generate the config file (`Config/config.yaml`)
- Create directories for `Logs` and `Database`
- Optionally generate a `.service` file for systemd

---

## 🔧 Optional: Running AIS as a Linux service

If you want the service to run in the background and restart automatically:

1. Copy the generated service file:

```bash
sudo cp /your/installation/path/alert-integration-service.service /etc/systemd/system/
```

2. Reload systemd, then enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable alert-integration-service
sudo systemctl start alert-integration-service
```

3. Check the status:

```bash
sudo systemctl status alert-integration-service
```

---

## 📝 Notes

- The `config.yaml` file is fully customizable. You can re-run the installer or edit it manually inside the `Config/` folder.
- Make sure the machine has outbound access to the ThousandEyes API and the destination endpoints (e.g., ServiceNow).

---

## 🛠 Support

If you run into issues or need help configuring, please contact the integrations team.
