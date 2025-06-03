//
//  KidDataView.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 02/06/25.
//

import SwiftUI

struct KidDataView: View {
    let kidName: String
    var kidCoins: Int
    
    var body: some View {
        HStack(spacing: 24) {
            Image(.iPerfil)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(kidName)
                    .font(.system(size: 28))
                    .fontWeight(.bold)
                
                RoundedCorner(radius: 20)
                    .fill(.backgroundRoundedRectangleCoins)
                    .frame(width: 98, height: 35)
                    .overlay(alignment:.center){
                        HStack (spacing: 8){
                            Image(.iCoin)
                                .frame(width: 24, height: 24)
                            
                            Text("\(kidCoins)")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .contentTransition(.numericText())
                        }
                    }
            }
            .frame(maxHeight: 80, alignment: .bottom)
            
        }
    }
}
