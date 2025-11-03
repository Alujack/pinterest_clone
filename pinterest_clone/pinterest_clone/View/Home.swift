//
//  Home.swift
//  pinterest_clone
//
//  Created by Realwat2007 on 30/10/25.
//

import SwiftUI

struct HomeView: View {
    var screen = NSScreen.main?.visibleFrame
    var body : some View {
        HStack{
            Sidebar()
            Spacer()
            
            
        }/*.frame(width: screen!.width, height:screen!.height)*/
            .background(Color.white.opacity(0.6))
            . background(BlurWindow())
            .ignoresSafeArea(.all, edges: .all)
        
    }
}

#Preview{
    HomeView()
}

struct Sidebar: View {
    @State var selected = "Home"
    @Namespace var animation
    var body: some View {
        HStack(spacing:0){
            VStack(spacing:22){
                Group{
                    HStack{
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:45, height:45)
                            .foregroundColor(.red)
                        Text("Pinterest")
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 35)
                    .padding(.leading, 10)
                    TabButton(
                        image:"house.fill",
                        title:"Home",
                        selected: $selected,
                        animation: animation)
                    
                    TabButton(
                        image:"clock.fill",
                        title:"Recent",
                        selected: $selected,
                        animation: animation)
                    
                    TabButton(
                        image:"person.2.fill",
                        title:"Followings",
                        selected: $selected,
                        animation: animation)
                    
                    HStack{
                        Text("Insignts")
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                        Spacer()
                    }.padding()
                    
                    TabButton(
                        image:"message.fill",
                        title:"message",
                        selected: $selected,
                        animation: animation)
                    
                    TabButton(
                        image:"bell.fill",
                        title:"Notifcations",
                        selected: $selected,
                        animation: animation)
                }
                VStack(spacing:8){
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Button(action:{}, label:{
                        Text("Bussiness Man")
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        
                    })
                    .buttonStyle(PlainButtonStyle())
                    Text("There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal,10)
                }
                Spacer(minLength: 0)
                HStack(spacing:10){
                    Image(systemName: "person")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:35, height:35, alignment:.center)
                    //                          .clipShape(.circle)
                    VStack(alignment: .leading, spacing:8, content:{
                        Text("Yoeurn Yan ")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        Text("Last Login at 30 10 2025")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                    })
                    Spacer(minLength: 0)
                    Image(systemName:"chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical,10)
                .padding(.horizontal,8)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color:Color.black.opacity(0.1), radius: 5, x:-5, y:-5)
                .padding(.horizontal)
                .padding(.bottom,20)
            }
            Divider()
                .offset(x:-2)
        }.frame(width:260)
    }
}
