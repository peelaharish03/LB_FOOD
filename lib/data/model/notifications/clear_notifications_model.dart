class ClearNotificationsModel {
    ClearNotificationsModel({
        required this.message,
    });

    final String? message;

    factory ClearNotificationsModel.fromJson(Map<String, dynamic> json){ 
        return ClearNotificationsModel(
            message: json["message"],
        );
    }

}
