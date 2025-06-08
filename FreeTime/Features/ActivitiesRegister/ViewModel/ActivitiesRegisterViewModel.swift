//
//  RecordViewModel.swift
//  FreeTime
//
//  Created by Pedro Larry Rodrigues Lopes on 07/05/25.
//

import SwiftUI

#warning("Para efeitos de organização, é importante remover classes que não estão sendo utilizadas.")

class ActivitiesRegisterViewModel: ObservableObject {
    
    @EnvironmentObject var coordinator: Coordinator

//    @Published var records: [ActivitiesRegister] {
//        didSet {
//            // Se a variável records mudar, a função checa se deve recompensar
//            rewardKid()
//        }
//    }
//        
//    init() {
//        self.records = [.sample1, .sample2, .sample1, .sample2]
//    }
//    
//    //TODO: checar se isso é necessário
//    func rewardKid(){
//        for record in records {
//            // if the activity registered is done
//            if record.registerStatus == .completed {
//                // reward kid with coins
////                coordinator.kid.addCoins(record.activity?.rewardPoints ?? 0)
//            }
//        }
//    }    
}
