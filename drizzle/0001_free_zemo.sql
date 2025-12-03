CREATE TABLE `camera_streams` (
	`id` int AUTO_INCREMENT NOT NULL,
	`camera_id` varchar(128) NOT NULL,
	`camera_description` text,
	`stream_type` enum('rtsp','video') NOT NULL,
	`rtsp_url` text,
	`video_url` text,
	`video_file_key` text,
	`user_id` int NOT NULL,
	`created_at` timestamp NOT NULL DEFAULT (now()),
	`updated_at` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
	CONSTRAINT `camera_streams_id` PRIMARY KEY(`id`),
	CONSTRAINT `camera_streams_camera_id_unique` UNIQUE(`camera_id`)
);
