package com.example.network_analyzer_app;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.telephony.CellInfo;
import android.telephony.CellInfoGsm;
import android.telephony.CellInfoLte;
import android.telephony.CellInfoNr;
import android.telephony.CellInfoWcdma;
import android.telephony.CellSignalStrengthGsm;
import android.telephony.CellSignalStrengthLte;
import android.telephony.CellSignalStrengthNr;
import android.telephony.CellSignalStrengthWcdma;
import android.telephony.TelephonyManager;
import android.telephony.ServiceState;
import android.util.Log;
import android.telephony.SignalStrength;
import android.net.wifi.WifiManager;
import android.content.SharedPreferences;
import android.provider.Settings;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.Enumeration;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL_NAME = "telephony_channel";
    private TelephonyManager telephonyManager;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL_NAME).setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("getTelephonyInfo")) {
                        Map<String, String> telephonyInfo = getTelephonyInfo();
                        result.success(telephonyInfo);
                    } else {
                        result.notImplemented();
                    }
                }
        );
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        telephonyManager = (TelephonyManager) getSystemService(Context.TELEPHONY_SERVICE);
        ServiceState serviceState = telephonyManager.getServiceState();
    }

    private Map<String, String> getTelephonyInfo() {
        Map<String, String> telephonyInfo = new HashMap<>();
        telephonyInfo.put("operator", telephonyManager.getNetworkOperatorName());
        telephonyInfo.put("signalPower", getSignalStrength());
        telephonyInfo.put("sinr", getSNR());
        telephonyInfo.put("networkType", getNetworkType());
        telephonyInfo.put("frequencyBand", getFrequencyBand());
        telephonyInfo.put("cellId", getCellInfo());
        telephonyInfo.put("macAddress", getMacAddressOrUniqueIdentifier(getApplicationContext()));
        telephonyInfo.put("ipAddress", getDeviceIpAddress());
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy hh:mm a", Locale.getDefault());
        telephonyInfo.put("timeStamp", sdf.format(new Date()));
        return telephonyInfo;
    }

    private String getNetworkType() {
        int networkType = telephonyManager.getNetworkType();
        String networkTypeString;
        switch (networkType) {
            case TelephonyManager.NETWORK_TYPE_GPRS:
            case TelephonyManager.NETWORK_TYPE_EDGE:
            case TelephonyManager.NETWORK_TYPE_CDMA:
            case TelephonyManager.NETWORK_TYPE_1xRTT:
            case TelephonyManager.NETWORK_TYPE_IDEN:
                networkTypeString = "2G";
                break;
            case TelephonyManager.NETWORK_TYPE_UMTS:
            case TelephonyManager.NETWORK_TYPE_EVDO_0:
            case TelephonyManager.NETWORK_TYPE_EVDO_A:
            case TelephonyManager.NETWORK_TYPE_HSDPA:
            case TelephonyManager.NETWORK_TYPE_HSUPA:
            case TelephonyManager.NETWORK_TYPE_HSPA:
            case TelephonyManager.NETWORK_TYPE_EVDO_B:
            case TelephonyManager.NETWORK_TYPE_EHRPD:
            case TelephonyManager.NETWORK_TYPE_HSPAP:
                networkTypeString = "3G";
                break;
            case TelephonyManager.NETWORK_TYPE_LTE:
                networkTypeString = "4G";
                break;
            default:
                networkTypeString = "Unknown";
        }

        return networkTypeString;
    }

    private String getSignalStrength() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR1) {
            CellInfo cellInfo = getCellInfoObject();
            if (cellInfo instanceof CellInfoLte) {
                CellSignalStrengthLte cellSignalStrength = ((CellInfoLte) cellInfo).getCellSignalStrength();
                return String.valueOf(cellSignalStrength.getDbm());
            } else {
                return "N/A";
            }
        } else {
            return "N/A";
        }
    }

    private String getSNR() {
    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.JELLY_BEAN_MR1) {
        CellInfo cellInfo = getCellInfoObject();
        if (cellInfo instanceof CellInfoLte) {
            CellSignalStrengthLte cellSignalStrength = ((CellInfoLte) cellInfo).getCellSignalStrength();

            int rssi = (int) (10 * Math.log10(cellSignalStrength.getRssi()));

            int rsrp = cellSignalStrength.getRsrp();

            int snr = -rsrp - rssi;

            return String.valueOf(Math.abs(snr));
        } else {
            return "N/A";
        }
    } else {
        return "N/A";
    }
}

    private CellInfo getCellInfoObject() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            List<CellInfo> cellInfoList = telephonyManager.getAllCellInfo();
            if (cellInfoList != null) {
                for (CellInfo cellInfo : cellInfoList) {
                    if (cellInfo.isRegistered()) {
                        return cellInfo;
                    }
                }
            }
        }
        return null;
    }

    private String getCellInfo() {
    CellInfo cellInfo = getCellInfoObject();
    if (cellInfo != null) {
        if (cellInfo instanceof CellInfoGsm) {
            CellInfoGsm cellInfoGsm = (CellInfoGsm) cellInfo;
            return cellInfoGsm.getCellIdentity().getMcc() + "-" + cellInfoGsm.getCellIdentity().getCid();
        } else if (cellInfo instanceof CellInfoLte) {
            CellInfoLte cellInfoLte = (CellInfoLte) cellInfo;
            return cellInfoLte.getCellIdentity().getMcc() + "-" + cellInfoLte.getCellIdentity().getCi();
        } else if (cellInfo instanceof CellInfoWcdma) {
            CellInfoWcdma cellInfoWcdma = (CellInfoWcdma) cellInfo;
            return cellInfoWcdma.getCellIdentity().getMcc() + "-" + cellInfoWcdma.getCellIdentity().getCid();
        }
    }
    return "";
    }


    private String getFrequencyBand() {
    List<CellInfo> cellInfoList = telephonyManager.getAllCellInfo();
    String frequencyBand = "";
    for (CellInfo cellInfo : cellInfoList) {
        if (cellInfo instanceof CellInfoGsm) {
            frequencyBand = String.valueOf(((CellInfoGsm) cellInfo).getCellIdentity().getArfcn());
            break;
        } else if (cellInfo instanceof CellInfoWcdma) {
            frequencyBand = String.valueOf(((CellInfoWcdma) cellInfo).getCellIdentity().getUarfcn());
            break;
        } else if (cellInfo instanceof CellInfoLte) {
            frequencyBand = String.valueOf(((CellInfoLte) cellInfo).getCellIdentity().getEarfcn());
            break;
        }
    }
    return frequencyBand;
}

    public static String getMacAddressOrUniqueIdentifier(Context context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
        return getMacAddress();
    } else {
        String uniqueIdentifier = getOrCreateUniqueIdentifier(context);
        return uniqueIdentifier;
    }
}

private static final String UNIQUE_IDENTIFIER_KEY = "unique_identifier";

private static String getOrCreateUniqueIdentifier(Context context) {
    SharedPreferences sharedPreferences = context.getSharedPreferences("MyPrefs", Context.MODE_PRIVATE);
    String uniqueIdentifier = sharedPreferences.getString(UNIQUE_IDENTIFIER_KEY, null);
    if (uniqueIdentifier == null) {
        uniqueIdentifier = generateUniqueIdentifier(context);
        sharedPreferences.edit().putString(UNIQUE_IDENTIFIER_KEY, uniqueIdentifier).apply();
    }
    return uniqueIdentifier;
}

private static String generateUniqueIdentifier(Context context) {
    String androidId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
    String uuid = UUID.randomUUID().toString();
    String combined = androidId + uuid;
    String macAddressLikeIdentifier = formatToMacAddressLikeString(combined);
    return macAddressLikeIdentifier;
}

private static String formatToMacAddressLikeString(String input) {
    if (input.length() < 12) {
        throw new IllegalArgumentException("Input string is too short");
    }
    StringBuilder macAddressBuilder = new StringBuilder();
    for (int i = 0; i < 12; i += 2) {
        if (i > 0) {
            macAddressBuilder.append(":");
        }
        macAddressBuilder.append(input.substring(i, i + 2));
    }
    return macAddressBuilder.toString();
}

private static String getMacAddress() {
    try {
        String interfaceName = "wlan0";
        List<NetworkInterface> interfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
        for (NetworkInterface inter_face : interfaces) {
            if (!inter_face.getName().equalsIgnoreCase(interfaceName)) {
                continue;
            }

            byte[] mac = inter_face.getHardwareAddress();
            if (mac == null) {
                return "";
            }

            StringBuilder buffer = new StringBuilder();
            for (byte aMac : mac) {
                buffer.append(String.format("%02X:", aMac));
            }
            if (buffer.length() > 0) {
                buffer.deleteCharAt(buffer.length() - 1);
            }
            return buffer.toString();
        }
    } catch (Exception ignored) {
    }
    return "";
}

public String getDeviceIpAddress() {
    String ipAddress = "";
    try {
        Enumeration<NetworkInterface> networkInterfaces = NetworkInterface.getNetworkInterfaces();
        while (networkInterfaces.hasMoreElements()) {
            NetworkInterface networkInterface = networkInterfaces.nextElement();
            Enumeration<InetAddress> inetAddresses = networkInterface.getInetAddresses();
            while (inetAddresses.hasMoreElements()) {
                InetAddress inetAddress = inetAddresses.nextElement();
                // Check if the IP address is not loopback and is IPv4
                if (!inetAddress.isLoopbackAddress() && inetAddress.getAddress().length == 4) {
                    ipAddress = inetAddress.getHostAddress();
                    break;
                }
            }
            if (!ipAddress.isEmpty()) {
                break;
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    return ipAddress;
}

}
