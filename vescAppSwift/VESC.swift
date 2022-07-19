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
public enum FailedCodes: Int {
    case FAULT_CODE_NONE = 0
    case FAULT_CODE_OVER_VOLTAGE
    case FAULT_CODE_UNDER_VOLTAGE
    case FAULT_CODE_DRV
    case FAULT_CODE_ABS_OVER_CURRENT
    case FAULT_CODE_OVER_TEMP_FET
    case FAULT_CODE_OVER_TEMP_MOTOR
    case FAULT_CODE_GATE_DRIVER_OVER_VOLTAGE
    case FAULT_CODE_GATE_DRIVER_UNDER_VOLTAGE
    case FAULT_CODE_MCU_UNDER_VOLTAGE
    case FAULT_CODE_BOOTING_FROM_WATCHDOG_RESET
    case FAULT_CODE_ENCODER
}
public enum COMM_PACKET_ID: Int {
    case COMM_GET_VALUES = 4
    case COMM_TERMINAL_CMD = 20
    case COMM_PRINT = 21
}

struct mc_values{
    var v_in = 0.0
    var temp_mos = 0.0
//    var temp_motor = 0.0
    var current_motor = 0.0
    var current_in = 0.0
//    var id = 0.0
//    var iq = 0.0
    var rpm = 0.0
//    var duty_now = 0.0
    var amp_hours = 0.0
    var amp_hours_charged = 0.0
    var watt_hours = 0.0
    var watt_hours_charged = 0.0
    var tachometer = 0
    var tachometer_abs = 0
    var fault_code = 0
    
    init(){
        
    }
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
    var messageReceived : [UInt8] = [UInt8](repeating: 0, count: 256)
    var payload : [UInt8] = []
    var values = mc_values()
    
    func crc16(data: [UInt8], length : Int) -> UInt16{
        var crc = 0
        let dataInt: [Int] = data.map{Int( $0) }
        
        for i in 0 ..< length {
            crc = ((crc & 0xFF) << 8) ^ crc16_tab[(((crc & 0xFF00) >> 8) ^  dataInt[i]) & 0xFF]
        }
        
        crc = crc & 0xFFFF
        return UInt16(crc)
    }
    
    func terminal(cmd: String) -> Data{
        var index = 0
        let packetLength = cmd.count + 1 // 1 is for command plus
        
        var command : [UInt8] = [UInt8](repeating: 0, count: packetLength + 5)
        
        command[index] = UInt8(PACKET_LENGTH.PACKET_LENGTH_IDENTIFICATION_BYTE_SHORT.rawValue)
        index += 1
        
        command[index] = UInt8(packetLength) // lenght of packet
        index += 1
        
        command[index] = UInt8(COMM_PACKET_ID.COMM_TERMINAL_CMD.rawValue);
        index += 1
                
        let asUInt8Array = cmd.utf8.map{ UInt8($0) }
        
        asUInt8Array.forEach { char in
            command[index] = char
            index += 1
        }
        
        var payloadCrc : [UInt8] = [UInt8](repeating: 0, count: packetLength)
        payloadCrc[0] = UInt8(COMM_PACKET_ID.COMM_TERMINAL_CMD.rawValue);
        var payloadTempIndex = 1
        asUInt8Array.forEach { char in
            payloadCrc[payloadTempIndex] = char
            payloadTempIndex += 1
        }
        let crc = crc16(data: payloadCrc, length: payloadCrc.count)
        
        command[index] = (UInt8)(crc >> 8)
        index += 1
        
        command[index] = (UInt8)(crc & 0xFF)
        index += 1
        
        command[index] = UInt8(PACKET_LENGTH.PACKET_TERMINATION_BYTE.rawValue)
        index += 1
        
        return Data(bytes: command, count: command.count)
    }
    
    func dataForGetValues() -> Data{
        
        var command : [UInt8] = [UInt8](repeating: 0, count: 6)
        command[0] = UInt8(PACKET_LENGTH.PACKET_LENGTH_IDENTIFICATION_BYTE_SHORT.rawValue)
        command[1] = 1
        command[2] = UInt8(COMM_PACKET_ID.COMM_GET_VALUES.rawValue);
        
        var payloadCrc : [UInt8] = [UInt8](repeating: 0, count: 1)
        payloadCrc[0] = UInt8(COMM_PACKET_ID.COMM_GET_VALUES.rawValue);
        let crc = crc16(data: payloadCrc, length: payloadCrc.count)
        
        command[3] = (UInt8)(crc >> 8)
        command[4] = (UInt8)(crc & 0xFF)
        command[5] = UInt8(PACKET_LENGTH.PACKET_TERMINATION_BYTE.rawValue)
        
        return Data(bytes: command, count: command.count)
    }
    
    func process_incoming_bytes(incomingData: Data) -> Int{
        
        let bytes: [UInt8] = incomingData.map{ $0 }
        
        for i in 0 ..< incomingData.count {
            
            if counter >= messageReceived.count{
                counter = 0
                for i in 0..<messageReceived.count{
                    messageReceived[i] = 0
                }
            }
            
            messageReceived[counter] = bytes[i]
            counter = counter + 1
            
            if counter == 2 {
                switch messageReceived[0]{
                    case 2:
                        endMessage = Int(messageReceived[1]) + 5
                        lenPayload = Int(messageReceived[1])
                        break;
                    case 3:
                    //ToDo: Add Message Handling > 255 (starting with 3)
                    break;
                    default:
                        break;
                }
            }
            
            if counter >= messageReceived.count{
                break;
            }
            
            if counter == endMessage && messageReceived[endMessage - 1] == UInt8(PACKET_LENGTH.PACKET_TERMINATION_BYTE.rawValue) {
                messageReceived[endMessage] = 0;
                messageRead = true;
                
                break;
            }
            
        }

        var unpacked = false;
        if (messageRead) {
            
            var crcMessage : UInt16
            crcMessage = UInt16(messageReceived[endMessage - 3]) << 8
            crcMessage &= 0xFF00
            crcMessage += UInt16(messageReceived[endMessage - 2])

            for i in 0 ..< lenPayload {
                payload.append(messageReceived[i+2])
            }
            
            let crcPayload = crc16(data:payload, length: lenPayload)

            if crcPayload == crcMessage {
                unpacked = true
            }
        }
        
        if (unpacked) {
            return lenPayload
        }
        else {
            return 0
        }
    }
    
    func buffer_get_int16(buffer: [UInt8], index : Int) -> UInt16{
        return UInt16(buffer[index]) << 8 | UInt16(buffer[index + 1])
    }
    func buffer_get_int32(buffer: [UInt8], index : Int) -> UInt32 {
        return UInt32(buffer[index]) << 24 | UInt32(buffer[index + 1]) << 16 | UInt32(buffer[index + 2]) << 8 | UInt32(buffer[index + 3])
    }
    func buffer_get_float16(buffer: [UInt8], scale : Double, index : Int) -> Double{
        return Double(buffer_get_int16(buffer: buffer, index: index)) / scale
    }
    func buffer_get_float32(buffer: [UInt8], scale : Double, index : Int) -> Double{
        return (Double)(buffer_get_int32(buffer: buffer, index: index)) / scale
    }
    
    func readPacket() -> mc_values{
        
        let packetId : COMM_PACKET_ID = COMM_PACKET_ID(rawValue: Int(payload[0]))!
        
        
        var payload2 : [UInt8] = []
        for i in 1 ..< payload.count {
            payload2.append(payload[i])
        }
        print("packetId \(packetId)")
        if packetId == COMM_PACKET_ID.COMM_GET_VALUES {
            var ind : Int = 0
            
            values.temp_mos = buffer_get_float16(buffer: payload2, scale: 1e1, index: ind)
            ind = ind + 2
            
//            values.temp_motor = buffer_get_float16(buffer: payload2, scale: 1e1, index: ind)
            ind = ind + 2
            
            values.current_motor = buffer_get_float32(buffer: payload2, scale: 1e2, index: ind)
            ind = ind + 4

            values.current_in = buffer_get_float32(buffer: payload2, scale:1e2, index:ind)
            ind = ind + 4
            
//            values.id = buffer_get_float32(buffer: payload2, scale:1e2, index:ind)
            ind = ind + 4
            
//            values.iq = buffer_get_float32(buffer: payload2, scale:1e2, index:ind)
            ind = ind + 4
            
//            values.duty_now = buffer_get_float16(buffer: payload2, scale:1e3, index:ind)
            ind = ind + 2
            
            values.rpm = buffer_get_float32(buffer: payload2,scale: 1e0, index:ind)
            ind = ind + 4
            
            values.v_in = buffer_get_float16(buffer: payload2,scale: 1e1, index:ind)
            ind = ind + 2
            
            values.amp_hours = buffer_get_float32(buffer: payload2, scale:1e4, index:ind)
            ind = ind + 4
            
            values.amp_hours_charged = buffer_get_float32(buffer: payload2, scale:1e4, index:ind)
            ind = ind + 4
            
            values.watt_hours = buffer_get_float32(buffer: payload2, scale:1e4, index:ind)
            ind = ind + 4
            
            values.watt_hours_charged = buffer_get_float32(buffer: payload2, scale:1e4, index:ind)
            ind = ind + 4
            
            values.tachometer = Int(buffer_get_int32(buffer: payload2, index:ind))
            ind = ind + 4
            
            values.tachometer_abs = Int(buffer_get_int32(buffer: payload2, index:ind))
            ind = ind + 4

            values.fault_code = Int(payload2[ind])
            ind = ind + 1
        } else if packetId == COMM_PACKET_ID.COMM_PRINT {
            if let string = String(bytes: payload2, encoding: .utf8) {
                print("TERMINAL: \(string)")
            }
        }
        
        resetPacket()
        
        return values
    }
    
    func resetPacket(){
        messageRead = false
        counter = 0
        endMessage = 256
        payload = []
        
        for i in 0..<messageReceived.count{
            messageReceived[i] = 0
        }
    }
    
}
