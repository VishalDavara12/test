//
//  ContentView.swift
//  Demo
//
//  Created by Vishal davara on 25/04/24.
//

import SwiftUI
import Foundation

struct Post: Codable, Identifiable {
    let id: Int
    let title: String
    let body: String
}
class DataService {
    private let baseURL = "https://jsonplaceholder.typicode.com"
    private let pageSize = 30
    private var currentPage = 1
    
    func fetchPosts(page: Int, completion: @escaping ([Post]?, Error?) -> Void) {
        let urlString = "\(baseURL)/posts?_page=\(page)&_limit=\(pageSize)"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            debugPrint(String(decoding: data, as: UTF8.self))
            do {
                let posts = try JSONDecoder().decode([Post].self, from: data)
                completion(posts, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
    }
    
    func loadMorePosts(completion: @escaping ([Post]?, Error?) -> Void) {
        currentPage += 1
        fetchPosts(page: currentPage, completion: completion)
    }
}

struct ContentView: View {
    @State private var posts: [Post] = []
    @State private var isLoading = false
    let dataService = DataService()
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollView in
                List(posts) { post in
                    NavigationLink(destination:
                                    VStack(spacing:20) {
                        Text(post.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(post.body)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    ) {
                        Text(post.title)
                            .id(post.id)
                            .onAppear {
                                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                                    self.getNextPageIfNecessary(encounteredIndex: index)
                                }
                            }
                    }
                }
                .navigationTitle("Posts")
                .onAppear(perform: fetchPosts)
            }
        }
    }
    
    private func getNextPageIfNecessary(encounteredIndex: Int) {
        guard encounteredIndex == posts.count - 1 else { return }
        loadMorePosts()
        
    }
    
    func fetchPosts() {
        guard !isLoading else { return }
        isLoading = true
        dataService.fetchPosts(page: 1) { fetchedPosts, error in
            if let fetchedPosts = fetchedPosts {
                self.posts = fetchedPosts
            } else if let error = error {
                print("Error fetching posts: \(error)")
            }
            isLoading = false
        }
    }
    
    func loadMorePosts() {
        guard !isLoading else { return }
        isLoading = true
        dataService.loadMorePosts { morePosts, error in
            if let morePosts = morePosts {
                self.posts.append(contentsOf: morePosts)
            } else if let error = error {
                print("Error loading more posts: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
