//
//  CardActivity.swift
//  FreeTime
//
//  Created by Ana Beatriz Seixas on 07/05/25.
//

import SwiftUI

struct CardActivity: View {
    var activity: Activity
    
    var body: some View {
        VStack {
            Rectangle()
//                .fill(activity.activityState.color)
                .frame(width: 120, height: 80)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        
//                        Image of the Planned Activity
                    
                        
                        Text(activity.name)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                        
//                        Planned time to carry out the activity
//
//                        Text(activity.hour)
//                            .font(.caption)
//                            .bold()
//                            .lineLimit(1)
                    }
                    
                        .padding(1),
                    alignment: .center
                )
        }
    }
}
