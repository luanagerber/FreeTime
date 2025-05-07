//
//  ChildView.swift
//  FreeTime
//
//  Created by Luana Gerber on 05/05/25.
//

import SwiftUI

struct ChildView: View {
    
    @State var record : Record = Record.sample1
    
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    
                    //Header
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 100,
                               height:100)
                    
                    VStack{
                        Text(record.child.name)
                            .font(.largeTitle)
                            .bold()
                        Text("$100")
                            .font(.title)
                            .bold()
                        
                    }
                    
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 100, height: 100)
                    
                    Text("Vamos fazer a\n atividade de hoje? ")
                        .font(.largeTitle)
                        .bold()
                    
                }
                
                Text("Atividades para hoje")
                    .font(.largeTitle)
                Text("Dia da semana, data, mês")
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 10){
//                        ForEach(record.activity.filter({ $0.activityState == .notStarted })){ activity in
//                            CardActivity(activity: activity)
//                        }
                    }
                }
                
                Text("Atividades Concluídas")
                    .font(.largeTitle)

                
//                if record.activity.filter({ $0.activityState == .completed }).isEmpty {
//                    Text("Nenhuma atividade concluída")
//}
                
//                else{
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: 10){
                            
//                            ForEach(record.activity.filter({ $0.activityState == .completed })){ activity in
//                                CardActivity(activity: activity)
//                            }
                        //}
                    }
                }
                
                
            }.ignoresSafeArea()
        }
    }
}

#Preview {
    ChildView()
}
