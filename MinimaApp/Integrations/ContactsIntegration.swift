import Contacts

/// "The Rolodex"
/// Integrates with Apple Contacts for people context.
public class ContactsIntegration {
    public static let shared = ContactsIntegration()
    
    private let store = CNContactStore()
    
    private init() {}
    
    /// Request contacts access
    public func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }
    
    /// Search contacts by name
    public func search(query: String) throws -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactJobTitleKey as CNKeyDescriptor
        ]
        
        let predicate = CNContact.predicateForContacts(matchingName: query)
        return try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
    }
    
    /// Get all contacts (for context building)
    public func getAllContacts() throws -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]
        
        var contacts: [CNContact] = []
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        
        try store.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }
        
        return contacts
    }
    
    /// Format contacts for LLM context
    public func formatForContext(_ contacts: [CNContact]) -> String {
        guard !contacts.isEmpty else { return "No contacts found." }
        
        var context = "Contacts:\n"
        for contact in contacts.prefix(10) {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let email = contact.emailAddresses.first?.value as String? ?? ""
            let org = contact.organizationName
            
            context += "- \(name)"
            if !email.isEmpty { context += " <\(email)>" }
            if !org.isEmpty { context += " (\(org))" }
            context += "\n"
        }
        return context
    }
    
    /// Find contact by email (for email context)
    public func findByEmail(_ email: String) throws -> CNContact? {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]
        
        let predicate = CNContact.predicateForContacts(matchingEmailAddress: email)
        return try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch).first
    }
}
