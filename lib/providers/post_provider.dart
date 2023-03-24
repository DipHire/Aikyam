import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:aikyam/models/post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PostProvider extends ChangeNotifier {
  final auth = FirebaseAuth.instance;

  Future createPost(Post post) async {
    try {
      List<dynamic> postImages = [];
      if (post.photos.isNotEmpty) {
        var storage = FirebaseStorage.instance;
        TaskSnapshot taskSnapshot = await storage
            .ref()
            .child(
                'Posts/${'${post.ngoid}${DateFormat('h:mm a').format(DateTime.now())}1'}')
            .putFile(post.photos[0]);
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        postImages.add(downloadUrl);
      }
      if (post.photos.length >= 2) {
        var storage = FirebaseStorage.instance;
        TaskSnapshot taskSnapshot = await storage
            .ref()
            .child(
                'Posts/${'${post.ngoid}${DateFormat('h:mm a').format(DateTime.now())}2'}')
            .putFile(post.photos[1]);
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        postImages.add(downloadUrl);
      }
      if (post.photos.length == 3) {
        var storage = FirebaseStorage.instance;
        TaskSnapshot taskSnapshot = await storage
            .ref()
            .child(
                'Posts/${'${post.ngoid}${DateFormat('h:mm a').format(DateTime.now())}3'}')
            .putFile(post.photos[2]);
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        postImages.add(downloadUrl);
      }
      CollectionReference ngos = FirebaseFirestore.instance.collection('Ngo');
      CollectionReference posts =
          FirebaseFirestore.instance.collection('Posts');
      var p = await posts.add({
        'NgoName': post.ngoname,
        'NgoCity': post.ncity,
        'Description': post.description,
        'NoOfVolunteers': post.noofVolunters,
        "Date": post.date,
        "Time": post.time,
        "Address": post.address,
        "City": post.city,
        "State": post.state,
        "NgoId": post.ngoid,
        "Country": post.country,
        "Photos": postImages,
      });

      post.id = p.id;
      List<dynamic> postId = [];
      await ngos.doc(post.ngoid).get().then((snapshot) {
        postId = snapshot['PostId'];
      });
      postId.add(post.id);
      await ngos.doc(post.ngoid).update({
        'PostId': postId,
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future updatePost(Post post) async {
    try {
      CollectionReference posts =
          FirebaseFirestore.instance.collection('Posts');
      var p = await posts.doc(post.id).update({
        'Description': post.description,
        'NgoName': post.ngoname,
        'NgoCity': post.ncity,
        'NoOfVolunteers': post.noofVolunters,
        "Date": post.date,
        "Time": post.time,
        "Address": post.address,
        "City": post.city,
        "State": post.state,
        "Ngoid": post.ngoid,
        "Country": post.country,
        "Photos": post.photos,
      });
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future applyPost(String pid, String userType) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('Users');
      CollectionReference ngo = FirebaseFirestore.instance.collection('Ngo');
      CollectionReference posts =
          FirebaseFirestore.instance.collection('Posts');

      var aName = "";
      var profilePic = "";
      if (userType == "User") {
        await users.doc(auth.currentUser!.uid).get().then((snapshot) {
          aName = snapshot['Name'];
          profilePic = snapshot['ProfilePic'];
        });
      } else {
        await ngo.doc(auth.currentUser!.uid).get().then((snapshot) {
          aName = snapshot['Name'];
          profilePic = snapshot['ProfilePic'];
        });
      }

      await posts
          .doc(pid)
          .collection("Applications")
          .doc(auth.currentUser!.uid)
          .set({
        "PhoneNo": auth.currentUser!.phoneNumber,
        "ApplicantName": aName,
        "ProfilePic": profilePic,
        "ApplicationStatus": "InProcess",
      });
      if (userType == "User") {
        List<dynamic> postId = [];
        await users.doc(auth.currentUser!.uid).get().then((snapshot) {
          postId = snapshot['AppliedPostId'];
        });
        postId.add(pid);
        await users.doc(auth.currentUser!.uid).update({
          'AppliedPostId': postId,
        });
      } else {
        List<dynamic> postId = [];
        await ngo.doc(auth.currentUser!.uid).get().then((snapshot) {
          postId = snapshot['AppliedPostId'];
        });
        postId.add(pid);
        await ngo.doc(auth.currentUser!.uid).update({
          'AppliedPostId': postId,
        });
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future acceptdeleteUser(String ar, String pid, String uid) async {
    print(uid);
    CollectionReference posts = FirebaseFirestore.instance
        .collection('Posts')
        .doc(pid)
        .collection("Applications");
    if (ar == "Accept") {
      await posts.doc(uid).update({
        "ApplicationStatus": "Accepted",
      });
    } else {
      await posts.doc(uid).update({
        "ApplicationStatus": "Rejected",
      });
    }
  }

  Future deletePost(String id) async {
    final db = FirebaseFirestore.instance;
    await db.collection("Posts").doc(id).delete();
    // TODO: DELETE ID FROM USERS AND NGO
  }


  Future<Post?> getPostDetails(String id) async {
    try {
      CollectionReference posts =
          FirebaseFirestore.instance.collection('Posts');

      Post post = Post(
        category: "",
        description: "",
        ngoid: "",
        id: id,
        noofVolunters: "",
        date: "",
        time: "",
        city: "",
        driveTitle: "",
        ncity: "",
        ngoname: "",
        state: "",
        address: "",
        country: "",
        photos: [],
      );
      if (id.isNotEmpty) {
        id = id;
      }
      await posts.doc(id).get().then((DocumentSnapshot query) {
        Map<String, dynamic> data = query.data() as Map<String, dynamic>;
        post = Post(
          category: "",
          description: data["Description"],
          ngoid: data["NgoId"],
          id: id,
          noofVolunters: data["NoOfVolunteers"],
          date: data["Date"],
          time: data["Time"],
          city: data["City"],
          driveTitle: "",
          ncity: data["NgoCity"],
          ngoname: data["NgoName"],
          state: data["State"],
          address: data["Address"],
          country: data["Country"],
          photos: data["Photos"],
        );
      }).catchError((e){
        print(e);
      });
      notifyListeners();
      return post;
    } catch (e) {
      print(e);
    }
  }

  Future<List<dynamic>> getAppliedID(String userType) async {
    try{
      List<dynamic> postId = [];
      if(userType == "Ngo")
        {
          CollectionReference ngo =  FirebaseFirestore.instance.collection("Ngo");
          await ngo.doc(auth.currentUser!.uid).get().then((snapshot) {
            postId = snapshot['AppliedPostId'];
          });
        }
      else
        {
          CollectionReference users =  FirebaseFirestore.instance.collection("Users");
          await users.doc(auth.currentUser!.uid).get().then((snapshot) {
            postId = snapshot['AppliedPostId'];
          });
        }
      notifyListeners();
      return postId;
    }catch(e){
      rethrow;
    }
  }
}
