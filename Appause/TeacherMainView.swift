//
//  TeacherMainView.swift
//  Appause
//
//  Created by Huy Tran on 4/16/24.
//  Revised by Rayanne Ohara on 09/12/2024
//  Revised by Rayanne Ohara on 10/01/2024
//  Modified by Dakshina EW on 11/04/2024
//
//  Revised by Rayanne Ohara on 10/14/2024

import SwiftUI
import FirebaseFirestore

struct TeacherMainView: View {
    @Binding var showNextView: DisplayState
    @StateObject var firestoreManager = FirestoreManager()
    @StateObject var studentList = StudentList()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    @State private var status: String = "Normal"
    @State private var generatedCode: String = ""
    @State private var selectedTab = 0
    
    @State var studentName = ""
    
    @State private var currentSchedule: String = "Normal Schedule" // Track the active schedule
    @State private var activePeriods: [(classID: String, startTime: Date, endTime: Date)] = [] // Active periods from the selected schedule
    @State private var isOverrideActive: Bool = false // Track whether the manual override is active
    
    // Array used to generate a random character string
    @State private var charList = ["1","2","3","4","5","6","7","8","9","0",
                                   "a","b","c","d","e","f","g","h","i","j",
                                   "k","l","m","n","o","p","q","r","s","t",
                                   "u","v","w","x","y","z"]
    
    var body: some View {
        NavigationView {
            TabView (selection: $selectedTab) {
                VStack {
                    Button(action: {
                        withAnimation {
                            showNextView = .mainTeacher
                        }
                    }) {
                        Text("MAIN")
                            .fontWeight(btnStyle.getFont())
                            .foregroundColor(btnStyle.getPathFontColor())
                            .frame(width: btnStyle.getWidth(),
                                   height: btnStyle.getHeight(),
                                   alignment: btnStyle.getAlignment())
                    }
                    .padding()
                    .background(btnStyle.getPathColor())
                    .cornerRadius(btnStyle.getPathRadius())
                    .padding(.top)
                    
                    Spacer()
                    
                    // Text displaying the current status of the app
                    Text("Status: " + status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                        .foregroundColor(Color("BlackWhite"))
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .padding(.leading, 105)
                    
                    // Lock/Unlock buttons
                    HStack {
                        if isOverrideActive {
                            VStack {
                                Button(action: {
                                    status = "Locked"
                                }) {
                                    Image(systemName: "lock")
                                        .padding(.trailing)
                                        .font(.system(size: 100))
                                        .foregroundColor(.red)
                                }
                                Text("Lock")
                                    .padding(.trailing)
                            }
                            VStack {
                                Button(action: {
                                    status = "Unlocked"
                                }) {
                                    Image(systemName: "lock.open")
                                        .padding(.leading)
                                        .font(.system(size: 100))
                                        .foregroundColor(.green)
                                }
                                Text("Unlock")
                            }
                        } else {
                            if activePeriods.first(where: { $0.startTime <= Date() && $0.endTime >= Date() }) != nil {
                                Text("Status: Locked")
                                    .font(.title)
                                    .foregroundColor(.red)
                            } else {
                                Text("Status: Unlocked")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 25)
                    
                    //                Text("Connect Code")
                    //                    .font(.title)
                    //                    .padding(1)
                    //                TextField("Press the button to generate a code", text: $generatedCode)
                    //                    .background(Color.white.opacity(0.25))
                    //                    .foregroundColor(Color("BlackWhite"))
                    //                    .multilineTextAlignment(.center)
                    //                    .overlay(RoundedRectangle(cornerRadius: 5)
                    //                        .stroke(lineWidth: 1))
                    //                    .textFieldStyle(.roundedBorder)
                    //                    .disabled(true)
                    //                    .padding(5)
                    //
                    //                Button(action: {
                    //                    generatedCode = ""
                    //                    for _ in 0..<6 {
                    //                        let randomNum = Int.random(in: 0..<36)
                    //                        generatedCode += charList[randomNum]
                    //                    }
                    //                }) {
                    //                    Text("Generate New Code")
                    //                        .padding()
                    //                        .fontWeight(btnStyle.getFont())
                    //                        .background(btnStyle.getPathColor())
                    //                        .foregroundColor(btnStyle.getPathFontColor())
                    //                        .cornerRadius(100)
                    //                }
                        .padding(.bottom, 25)
                    
                    VStack {
                        Text("Teachers")
                            .font(.title)
                            .padding(.bottom, 10)
                        
                        ScrollView {
                            VStack {
                                ForEach(firestoreManager.Teachers, id: \.teacherID) { teacher in
                                    HStack {
                                        Text(teacher.Name)
                                            .font(.callout)
                                            .foregroundColor(btnStyle.getBtnFontColor())
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(0)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("Manual Override", isOn: $isOverrideActive)
                        .padding()
                        .onChange(of: isOverrideActive) { value in
                            if !value { status = "Normal" }
                        }
                    
                    //                Toggle("Dark Mode", isOn: $isDarkMode)
                    //                    .padding()
                }
                .onAppear {
                    firestoreManager.fetchTeachers()  // Fetch teachers when the view appears
                    loadActiveSchedule()
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0) // Add a unique tag to track this tab
                
                TeacherAllRequestsView()
                    .tabItem {
                        Image(systemName: "hand.raised")
                        Text("Requests")
                    }
                    .tag(1) // Unique tag for this tab
                TeacherClassListView()
                            .tabItem {
                                Image(systemName: "list.bullet")
                                Text("My Classes")
                            }
                            .tag(2) // Unique tag for this tab
                        
                        TeacherScheduleView()
                            .tabItem {
                                Image(systemName: "bell")
                                Text("Schedule")
                            }
                            .tag(3) // Unique tag for this tab
                        
                        ClassIDGenerationView()
                            .tabItem {
                                Image(systemName: "plus.square")
                                Text("Create New Class")
                            }
                            .tag(4) // Unique tag for this tab
                        
                        TeacherManageUsers()
                            .tabItem {
                                Image(systemName: "person.2")
                                Text("Students")
                            }
                            .tag(5) // Unique tag for this tab
                        
                        TeacherManageClasses()
                            .tabItem {
                                Image(systemName: "menucard.fill")
                                Text("All Classes")
                            }
                            .tag(6) // Unique tag for this tab
                            .environmentObject(studentList)
                        
                        BluetoothManagerView()
                            .tabItem {
                                Image(systemName: "app.connected.to.app.below.fill")
                                Text("Connectivity Manager")
                            }
                            .tag(7) // Unique tag for this tab
                        
                        TeacherWhitelist()
                            .tabItem {
                                Image(systemName: "lock.open")
                                Text("WhiteLists")
                            }
                            .tag(8) // Unique tag for this tab
                        
                        TeacherBlacklist()
                            .tabItem {
                                Image(systemName: "lock.fill")
                                Text("BlackLists")
                            }
                            .tag(9) // Unique tag for this tab
                        
                        TeacherSettingsView(showNextView: $showNextView)
                            .tabItem {
                                Image(systemName: "gear")
                                Text("Settings")
                            }
                            .tag(10) // Unique tag for this tab
            }
        }
    }
    // Load the active schedule's periods
    func loadActiveSchedule() {
        let db = Firestore.firestore()
        db.collection("schedules").document(currentSchedule).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                if let periodsData = data?["periods"] as? [[String: Any]] {
                    activePeriods = periodsData.compactMap { periodDict in
                        guard let classID = periodDict["classID"] as? String,
                              let startTime = periodDict["startTime"] as? Timestamp,
                              let endTime = periodDict["endTime"] as? Timestamp else { return nil }
                        return (classID, startTime.dateValue(), endTime.dateValue())
                    }
                }
            } else {
                print("Error loading active schedule: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // Date formatter for displaying time
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Format time as "hh:mm AM/PM"
        return formatter.string(from: date)
    }
}

struct TeacherMainView_Previews: PreviewProvider {
    @State static private var showNextView: DisplayState = .mainTeacher
        
        static var previews: some View {
            TeacherMainView(showNextView: $showNextView)
                .environmentObject(ScheduleState())
                .environmentObject(StudentList())
                .environmentObject(FirestoreManager())
    }
}
