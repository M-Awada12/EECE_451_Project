# Mobile Network Analyzer

Note: We are using a free web hosting service that shuts down the backend server if not active for 30 minutes, so please wait for about two minutes if anything doesn't open directly as the server is powering up during this time.

### Step 1: Clone the Repository

## To run the app, you have two options:

### First Option (Optimal Option):
1. Transfer the "Mobile_Network_Analyzer.apk" file to an Android device.
2. Install the apk file.
3. Go to settings and allow all required permissions

### Second Option:
1. Have Flutter installed.
2. Open the directory `EECE_451_Project/network_analyzer_app` in VS Code.
3. Choose an Android emulator.
4. Open the file `EECE_451_Project\network_analyzer_app\lib\main.dart` and select start debugging.

## To run the server, you also have two options:

### First Option:
As the server is already running on the cloud, you can see its documentation on the following link: [Four51 Server Documentation](https://four51-server.onrender.com/docs), but wait for two minutes for it to open if it doesn't show directly.

### Second Option:
1. Have Python installed.
2. Navigate to `EECE_451_Project\server\network_analyzer_server.py`: `cd EECE_451_Project\server`.
3. Run: `pip install -r requirements.txt`.
4. Run: `python network_analyzer_server.py`.

## To run the server web app:

### First Option:
As the server is already running on the cloud, you can see it on the following link: [Mobile Network Analyzer Web App](https://mobilenetworkanalyzer.netlify.app), but also wait for about two minutes for the server to power up.

### Second Option:
1. Have npm installed.
2. Navigate to `EECE_451_Project\server_web_app`: `cd EECE_451_Project\server_web_app`.
3. Run: `npm install` to install project dependencies.
4. Run: `npm start`.
