import SwiftUI
import TinkLink

struct CredentialsKindPicker: View {
    var credentialsKinds: [ProviderTree.CredentialsKindNode]

    var body: some View {
        List(credentialsKinds, id: \.id) { credentialsKind in
            NavigationLink(destination: Text(credentialsKind.provider.displayName)) {
                switch credentialsKind.credentialsKind {
                case .password:
                    Text("Password")
                case .mobileBankID:
                    Text("Mobile BankID")
                case .thirdPartyAuthentication:
                    Text("Third Party Authentication")
                case .keyfob:
                    Text("Key Fob")
                case .fraud:
                    Text("Fraud")
                case .unknown:
                    Text("Unknown")
                }
            }
        }
        .navigationTitle("Choose Credentials Type")
    }
}

struct CredentialsKindPicker_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsKindPicker(credentialsKinds: [])
    }
}
