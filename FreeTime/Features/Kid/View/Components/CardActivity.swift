//
//  CardActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 07/05/25.
//

import SwiftUI

struct CardActivity: View {
    var record: Register
    
    var body: some View {
        VStack{
            Rectangle()
                .fill(.white)
                .frame(width: 360, height: 200)
            
                .overlay(
                    VStack(spacing: 0) {
                        
                        //Image of the Planned Activity
                        Rectangle()
                            .fill(record.registerStatus.color)
                        
                        Rectangle()
                            .fill(.gray)
                            .frame(height: 55)
                            .overlay{
                                
                                VStack(spacing: 0){
                                    
                                    Text(record.activity?.name ?? "no name")
                                        .font(.system(size: 22, weight: .medium))
                                    
                                    Text(record.date.timeRange(duration: record.duration))
                                        .font(.system(size: 17, weight: .medium))
                                    
                                }
                                .lineLimit(1)
                                .foregroundColor(.white)
                            }
                        
                    }
                    
                )
        }.cornerRadius(20)
    }
}


#Preview {
    CardActivity(record: .sample1)
}
