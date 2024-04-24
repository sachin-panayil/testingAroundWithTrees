//
//  ContentView.swift
//  AlpineTechnicalInterview
//
//  Created by Sachin Panayil on 4/22/24.
//

import SwiftUI

struct ContentView: View {
  @State var name: String = "test"
  @State var isSheetOpen: Bool = false
  @State var isErrorMessageOpen: Bool = false
  @State var image: UIImage? = UIImage(named: "swift 2")!
  @State var isLoading: Bool = false
  @State var imageResponse: ImageResponse?
  
  let fixedSize: CGFloat = 300
  
  var body: some View {
    GeometryReader { geometry in
      List {
        if isLoading {
          ProgressView()
        } else {
          if let image = image {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .frame(width: min(fixedSize, geometry.size.width),
                     height: min(fixedSize, geometry.size.height))
          }
        }
        
        Section {
          Button {
            isSheetOpen.toggle()
          } label: {
            Text("Change Name")
          }
          Text(name)
        }
        
        Button {
          Task {
            /// Downloading an image
//            isLoading = true
//
//            do {
//              let response = try await downloadImage()
//              DispatchQueue.main.async {
//                image = response
//              }
//
//            } catch {
//              print(error)
//            }
//
//            isLoading = false
            
            /// Uploading an image
            try await uploadImage()
            isErrorMessageOpen = true
          }
          
          isErrorMessageOpen = true
        } label: {
          Text("Send Image")
        }
        
        /// If this was a real networking case, we would use this
//        if let imageResponse = imageResponse {
//          Text("Send Response: ERROR")
//        }
        
        if isErrorMessageOpen {
          Text("Send Response: ERROR")
        }
      }
    }
    .sheet(isPresented: $isSheetOpen, content: {
      NavigationView {
        List {
          TextField(
            "change your name",
            text: $name
          ).onChange(of: name) { isErrorMessageOpen = false }
        }
        .toolbar {
          Button {
            isSheetOpen = false
          } label: {
            Text("Done")
          }
        }
      }
    })
  }
  
  /// This should be handled  in a View Model
  func uploadImage() async throws {
    
    guard let image = image else {
      throw ImageError.invalidImage
    }
    
    guard let imageData = getImageData(image: image) else {
      throw ImageError.invalidData
    }
    
    do {
      let response = try await uploadImageData(imageData: imageData)
      imageResponse = response
    } catch {
      print(error)
    }
  }
  
}

//MARK: Structs for networking
struct DownloadedImage: Codable {
  let name: String
  let imageData: String
}

struct ImageResponse: Codable {
  let status: String
  let message: String
}

//MARK: GET Requests
func downloadImage() async throws -> DownloadedImage {
  let endpoint = "google.com"
  
  guard let url = URL(string: endpoint) else {
    throw NetworkError.invalidURL
  }
  
  let (data, response) = try await URLSession.shared.data(from: url)
  
  guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
    throw NetworkError.invalidResponse
  }
  
  do {
    let decoder = JSONDecoder()
    return try decoder.decode(DownloadedImage.self, from: data)
  } catch {
    throw NetworkError.invalidData
  }
}

//MARK: POST Requests
func getImageData(image: UIImage) -> Data? {
  return image.jpegData(compressionQuality: 1.0)
}

func uploadImageData(imageData: Data) async throws -> ImageResponse {
  let endpoint = "google.com"
  
  guard let url = URL(string: endpoint) else {
    throw NetworkError.invalidURL
  }
  
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
  
  let (data, response) = try await URLSession.shared.upload(for: request, from: imageData)
  
  guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
    throw NetworkError.invalidResponse
  }
  
  do {
    let decoder = JSONDecoder()
    return try decoder.decode(ImageResponse.self, from: data)
  } catch {
    throw NetworkError.invalidData
  }
}

//MARK: Error handling
enum NetworkError: Error {
  case invalidURL
  case invalidResponse
  case invalidData
}

enum ImageError: Error {
  case invalidData
  case invalidImage
}

#Preview {
  ContentView(name: "test", isSheetOpen: false)
}
