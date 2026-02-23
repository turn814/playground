ram_app_codes = \
{
    "0xF2A00001": {
        "status": "CYAPP_SUCCESS",
        "descr": "The provisioning application completed successfully"
    },
    "0x45000002": {
        "status": "CYAPP_BAD_PARAM",
        "descr": "One or more invalid parameters"
    },
    "0x45000003": {
        "status": "CYAPP_LOCKED",
        "descr": "Resource lock failure"
    },
    "0x45000004": {
        "status": "CYAPP_STARTED",
        "descr": "Operation started but not necessarily completed yet"
    },
    "0x45000005": {
        "status": "CYAPP_FINISHED",
        "descr": "Operation finished"
    },
    "0x45000006": {
        "status": "CYAPP_CANCELED",
        "descr": "Operation canceled"
    },
    "0x45000007": {
        "status": "CYAPP_TIMEOUT",
        "descr": "Operation timed out"
    },
    "0xF2A00010": {
        "status": "CYAPP_APP_RUNNING",
        "descr": "The provisioning application is in-progress"
    },
    "0x45000020": {
        "status": "CYAPP_OTP_INIT_FAILED",
        "descr": "Fail to initialize OTP"
    },
    "0x45000021": {
        "status": "CYAPP_OTP_BOOTROW_WRITE_FAILED",
        "descr": "Fail to update LCS"
    },
    "0x45000022": {
        "status": "CYAPP_OTP_BOOTROW_READ_FAILED",
        "descr": "Fail to read LCS"
    },
    "0x45000023": {
        "status": "CYAPP_OTP_WRITE_FAILED",
        "descr": "Fail to program object into OTP"
    },
    "0x45000024": {
        "status": "CYAPP_OTP_READ_FAILED",
        "descr": "Fail to read object from OTP"
    },
    "0x45000030": {
        "status": "CYAPP_LCS_INVALID",
        "descr": "Current device LCS is illegal to perform provisioning or re-provisioning"
    },
    "0x45000031": {
        "status": "CYAPP_OEM_KEY_ALREADY_REVOKED",
        "descr": "The OEM key 0 was revoked. This is operation can be done only once"
    },
    "0x45000032": {
        "status": "CYAPP_ICV_KEY_ALREADY_REVOKED",
        "descr": "The ICV key 0 was revoked. This is operation can be done only once"
    },
    "0x45000033": {
        "status": "CYAPP_SIGNATURE_VERIF_FAILED",
        "descr": "Fail to verify input parameters digital signature"
    },
    "0x45000034": {
        "status": "CYAPP_KEY_0_ALREADY_PROGRAMMED",
        "descr": "The OEM key 0 was programmed. This is operation can be done only once"
    },
    "0x45000035": {
        "status": "CYAPP_KEY_1_ALREADY_PROGRAMMED",
        "descr": "The OEM key 1 was programmed. This is operation can be done only once"
    },
    "0x45000036": {
        "status": "CYAPP_OEM_ASSETS_ALREADY_PROGRAMMED",
        "descr": "The OEM assets were programmed. This is operation can be done only once"
    },
    "0x45000037": {
        "status": "CYAPP_OEM_SECURE_KEY_ALREADY_PROGRAMMED",
        "descr": "The OEM_SECURE_KEY assets is programmed. This is operation can be done only once"
    },
    "0x45000100": {
        "status": "CYAPP_PARAM_NV_CNT_INVALID",
        "descr": "The input parameter NV counter is not valid"
    },
    "0x45000101": {
        "status": "CYAPP_PARAM_OEM_KEY_0_HASH_INVALID",
        "descr": "The input parameter OEM key 0 hash is not valid"
    },
    "0x45000102": {
        "status": "CYAPP_PARAM_OEM_KEY_1_HASH_INVALID",
        "descr": "The input parameter OEM key 1 hash is not valid"
    },
    "0x45000103": {
        "status": "CYAPP_PARAM_PUBKEY_INVALID",
        "descr": "The OEM public key for the digital signature verification does not correspond to OEM public key hash provisioned in the OTP"
    },
    "0x45000104": {
        "status": "CYAPP_PARAM_CONTROL_WORD_INVALID",
        "descr": "The input parameter control word is not valid"
    },
    "0x45000105": {
        "status": "CYAPP_PARAM_TARGET_LCS_INVALID",
        "descr": "The input parameter target LCS is not valid. The range of valid values is NORMAL, NORMAL_NO_SECURE and SECURE"
    },
    "0x45000106": {
        "status": "CYAPP_RMA_CERT_VERIF_FAILED",
        "descr": "Fail to verify certificate for RMA LCS transition"
    },
    "0x45000107": {
        "status": "CYAPP_PARAM_ACCESS_RESTRICT_INVALID",
        "descr": "The input parameter ACCESS_RESTRICT has invalid configuration"
    },
    "0x45000108": {
        "status": "CYAPP_PARAM_OEM_SECURE_KEY_INVALID",
        "descr": "The input parameter OEM_SECURE_KEY is not valid"
    }
}