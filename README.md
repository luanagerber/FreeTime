# iupi

> **Organizando a brincadeira**

O iupi é um aplicativo iOS projetado para famílias que buscam organizar a rotina de lazer de crianças entre 8 e 11 anos. Através de uma plataforma gamificada, pais e filhos colaboram para transformar o tempo livre em momentos de atividades saudáveis e recompensadoras.

## Sobre o Projeto

O aplicativo opera em um ecossistema duplo, conectando dispositivos via **CloudKit** para garantir que a gestão seja feita pelos adultos e a execução pelas crianças, promovendo autonomia e responsabilidade.

### Perfis de Uso

O iupi oferece experiências distintas baseadas no dispositivo e no papel do usuário:

* **Responsável (iPhone):** Focado na gestão. O adulto cria tarefas, monitora o cumprimento das atividades e gerencia o "banco" de recompensas.
* **Criança (iPad):** Focado na execução e gamificação. A criança visualiza sua agenda visual, marca atividades como concluídas, acumula moedas (coins) e troca por prêmios na loja virtual.

## Funcionalidades Principais

### Para os Pais (Genitor)
* **Gestão de Dependentes:** Adicione perfis de crianças e gere links de compartilhamento via iCloud.
* **Agendamento de Atividades:** Crie tarefas categorizadas (ex: Leitura, Desenho, Passeio) definindo data e duração.
* **Controle de Recompensas:** Aprove ou edite recompensas resgatadas pelas crianças.
* **Monitoramento:** Acompanhe o histórico de atividades realizadas e pendentes.

### Para as Crianças (Kid)
* **Agenda Visual:** Visualize as atividades do dia de forma clara e lúdica.
* **Gamificação:** Ganhe moedas virtuais ao completar tarefas saudáveis.
* **Loja de Recompensas:** Troque moedas acumuladas por prêmios cadastrados pelos pais (ex: Festa do Pijama, Cinema, Dinheiro).
* **Feedback Imediato:** Animações e feedbacks visuais ao concluir tarefas.

## Tecnologias e Arquitetura

O projeto foi desenvolvido utilizando as tecnologias modernas do ecossistema Apple:

* **Linguagem:** Swift 5.
* **Interface:** SwiftUI.
* **Arquitetura:** MVVM-C (Model-View-ViewModel + Coordinator) para navegação e separação de responsabilidades.
* **Backend/Sincronização:** CloudKit Nativo.
    * Uso de `CKShare` para compartilhamento de dados entre a conta iCloud do pai e do filho.
    * Bancos de dados Privado (PrivateDB) e Compartilhado (SharedDB).
* **Persistência:** Dados locais e remotos sincronizados via CloudKit.

## Como Rodar o Projeto

### Pré-requisitos
* Mac com Xcode 15+ instalado.
* Conta de Desenvolvedor Apple (necessária para o CloudKit e Push Notifications).
* Dois dispositivos físicos (um iPhone e um iPad) recomendados para testar o fluxo de compartilhamento real.

### Configuração do CloudKit
1.  Selecione o target `FreeTime` no Xcode.
2.  Vá em **Signing & Capabilities**.
3.  Certifique-se de que "iCloud" está ativado e "CloudKit" está marcado.
4.  Crie ou selecione um Container CloudKit personalizado.
5.  O app requer a criação de uma *Custom Zone* chamada `Kids` para permitir o compartilhamento hierárquico.

### Instalação
1.  Clone este repositório:
    ```bash
    git clone [https://github.com/seu-usuario/FreeTime.git](https://github.com/seu-usuario/FreeTime.git)
    ```
2.  Abra o arquivo `FreeTime.xcodeproj`.
3.  Aguarde a resolução dos pacotes Swift.
4.  Selecione seu time de desenvolvimento para assinar o app.
5.  Compile e rode (`Cmd + R`).

## Estrutura do Projeto

* `Coordinator/`: Gerencia o fluxo de navegação do app (Home, GenitorFlow, KidFlow).
* `Features/`:
    * `Genitor/`: Views e ViewModels exclusivas do perfil dos pais.
    * `Kid/`: Views e ViewModels exclusivas do perfil da criança.
    * `Rewards/`: Lógica da loja e sistema de moedas.
    * `ActivitiesRegister/`: Lógica de registro e conclusão de atividades.
* `Services/`: Camada de serviço do CloudKit (`CloudService.swift`, `CloudClient.swift`).
* `Utilities/`: Helpers, extensões e constantes.

## Autores

* **Ana Beatriz Seixas**
* **Isadora Cristina Farias Bastos**
* **Kássia Feitoza Siqueira**
* **Luana Rafaela Gerber**
* **Maria Tereza Martins Pérez**
* **Pedro Larry Rodrigues Lopes**
* **Thales Araújo de Souza**
