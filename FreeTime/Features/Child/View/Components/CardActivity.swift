//
//  CardActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 07/05/25.
//

import SwiftUI

struct CardActivity: View {
    var record: Record
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(record.recordStatus.color)
                .frame(width: 120, height: 80)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        
//                        Image of the Planned Activity
                    
                        
                        Text(record.activity.name)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                        


                        Text(record.duration.description)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                    }
                    
                        .padding(1),
                    alignment: .center
                )
        }
    }
}
