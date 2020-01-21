//
//  VESC.swift
//  VESC_IOS_SWIFT
//
//  Created by Bosko Petreski on 1/21/20.
//  Copyright © 2020 Bosko Petreski. All rights reserved.
//

import UIKit

enum PACKET_LENGTH: Int {
    case PACKET_LENGTH_IDENTIFICATION_BYTE_SHORT = 2
    case PACKET_TERMINATION_BYTE = 3
}

enum COMM_PACKET_ID: Int {
    case COMM_GET_VALUES_SETUP_SELECTIVE = 51
}

struct mc_values{
    var v_in = 0.0
    var temp_mos = 0.0
    var temp_motor = 0.0
    var current_motor = 0.0
    var current_in = 0.0
    var vesc_num = 0
    var rpm = 0.0
    var duty_now = 0.0
    var amp_hours = 0.0
    var amp_hours_charged = 0.0
    var watt_hours = 0.0
    var watt_hours_charged = 0.0
    var tachometer = 0
    var tachometer_abs = 0
    var fault_code = 0
    var pid_pos = 0.0
    var vesc_id = 0
    var speed = 0.0
    var battery_level = 0.0
    var watt_left = 0.0
}

class VESC: NSObject {
    
    let crc16_tab : [Int] = [0x0000, 0x1021, 0x2042, 0x3063, 0x4084,
    0x50a5, 0x60c6, 0x70e7, 0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad,
    0xe1ce, 0xf1ef, 0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7,
    0x62d6, 0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485, 0xa56a,
    0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d, 0x3653, 0x2672,
    0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4, 0xb75b, 0xa77a, 0x9719,
    0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc, 0x48c4, 0x58e5, 0x6886, 0x78a7,
    0x0840, 0x1861, 0x2802, 0x3823, 0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948,
    0x9969, 0xa90a, 0xb92b, 0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50,
    0x3a33, 0x2a12, 0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b,
    0xab1a, 0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
    0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49, 0x7e97,
    0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70, 0xff9f, 0xefbe,
    0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78, 0x9188, 0x81a9, 0xb1ca,
    0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f, 0x1080, 0x00a1, 0x30c2, 0x20e3,
    0x5004, 0x4025, 0x7046, 0x6067, 0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d,
    0xd31c, 0xe37f, 0xf35e, 0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214,
    0x6277, 0x7256, 0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c,
    0xc50d, 0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c, 0x26d3,
    0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634, 0xd94c, 0xc96d,
    0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab, 0x5844, 0x4865, 0x7806,
    0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3, 0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e,
    0x8bf9, 0x9bd8, 0xabbb, 0xbb9a, 0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1,
    0x1ad0, 0x2ab3, 0x3a92, 0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b,
    0x9de8, 0x8dc9, 0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0,
    0x0cc1, 0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
    0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0]
    
    var counter = 0
    var endMessage = 256
    var messageRead = false
    var lenPayload = 0
    var messageReceived : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    var payload : [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    
    func crc16(data: [UInt8], length : Int) -> UInt16{
        var crc = 0
        let dataInt: [Int] = data.map{Int( $0) }
        
        for i in 0 ..< length {
            crc = ((crc & 0xFF) << 8) ^ crc16_tab[(((crc & 0xFF00) >> 8) ^  dataInt[i]) & 0xFF]
        }
        
        crc = crc & 0xFFFF
        return UInt16(crc)
    }
    
    func dataForGetValues() -> Data{
        
        var command : [UInt8] = [0,0,0,0,0]
        command[0] = UInt8(COMM_PACKET_ID.COMM_GET_VALUES_SETUP_SELECTIVE.rawValue);
        command[1] = 0x00 ; //mask MSB
        command[2] = 0x0F ; //mask
        command[3] = 0xFF ; //mask
        command[4] = 0xFF ; //mask LSB
        
        let crcPayload = crc16(data: command, length: command.count)
        var messageSend : [UInt8]  = [0,0,0,0,0,0,0,0,0,0]
        
        messageSend[0] = UInt8(PACKET_LENGTH.PACKET_LENGTH_IDENTIFICATION_BYTE_SHORT.rawValue)
        messageSend[1] = 5;
        messageSend[2] = UInt8(COMM_PACKET_ID.COMM_GET_VALUES_SETUP_SELECTIVE.rawValue)
        messageSend[3] = 0x00
        messageSend[4] = 0x0F
        messageSend[5] = 0xFF
        messageSend[6] = 0xFF
        messageSend[7] = (UInt8)(crcPayload >> 8)
        messageSend[8] = (UInt8)(crcPayload & 0xFF)
        messageSend[9] = UInt8(PACKET_LENGTH.PACKET_TERMINATION_BYTE.rawValue)
        
        return Data(bytes: messageSend, count: messageSend.count)
    }
    
    func process_incoming_bytes(incomingData: Data) -> Int{
        
        let bytes: [UInt8] = incomingData.map{ $0 }
        
        for i in 0 ..< incomingData.count {
            messageReceived.insert(UInt8(bytes[i]), at: counter)
            counter = counter + 1
            
            if counter == 2 {
                switch messageReceived[0]{
                    case 2:
                        endMessage = Int(messageReceived[1]) + 5
                        lenPayload = Int(messageReceived[1])
                        break;
                    default:
                        break;
                }
            }
            
            if counter >= messageReceived.count{
                break;
            }
            
            if counter == endMessage && messageReceived[endMessage - 1] == 3 {
                messageReceived[endMessage] = 0;
                messageRead = true;
                
                break;
            }
            
        }

        var unpacked = false;
        if (messageRead) {
            unpacked = UnpackPayload(message: messageReceived, lenMes: endMessage, lenPay: Int(messageReceived[1]))
        }
        
        if (unpacked) {
            return lenPayload
        }
        else {
            return 0
        }
    }
    
    func UnpackPayload(message : [UInt8], lenMes : Int, lenPay : Int) -> Bool{
        
        var crcMessage = 0;
        var crcPayload = 0;
        
        
        var tmpMessage = message
        
        crcMessage = Int(message[lenMes - 3] << 8)
        crcMessage &= 0xFF00
        crcMessage = crcMessage + Int(message[lenMes - 2])
        
        memcpy(&payload, &tmpMessage[2], Int(message[1]))
        
        crcPayload = Int(crc16(data: payload, length: Int(message[1])))
        print("\(crcPayload)  \(crcMessage)")
        if crcPayload == crcMessage {
            return true
        }
        else {
            return false
        }
    }
    
    func readPacket(){
        resetPacket()
    }
    
    func resetPacket(){
        messageRead = false
        counter = 0
        endMessage = 256
        
        messageReceived = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        payload = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    }
    
}
