<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\PushNotification;
use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AdminNotificationController extends Controller
{
    /**
     * Get history of broadcast push notifications.
     */
    public function index(Request $request): JsonResponse
    {
        $notifications = PushNotification::with("creator:id,name,email")
            ->latest()
            ->paginate($request->input("per_page", 20));

        return response()->json([
            "success" => true,
            "data"    => $notifications,
        ]);
    }

    /**
     * Get users list formatted for admin target selection checklist.
     */
    public function getUsers(Request $request): JsonResponse
    {
        $users = User::with("shop:id,name,phone")
            ->select("id", "shop_id", "name", "email", "mobile", "role", "created_at")
            ->orderBy("name", "asc")
            ->get()
            ->map(function ($user) {
                return [
                    "id"         => $user->id,
                    "name"       => $user->name,
                    "email"      => $user->email ?? "N/A",
                    "mobile"     => $user->mobile ?? ($user->phone ?? "N/A"),
                    "role"       => ucfirst($user->role ?? "user"),
                    "shop_name"  => $user->shop->name ?? "No Shop",
                    "created_at" => $user->created_at ? $user->created_at->format("d M Y") : "",
                ];
            });

        return response()->json([
            "success" => true,
            "data"    => $users,
        ]);
    }

    /**
     * Broadcast manual notification with Title, Description, Image, and Filter targeting.
     */
    public function send(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            "title"               => "required|string|max:255",
            "description"         => "required|string",
            "image"               => "nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120",
            "image_url"           => "nullable|string|url",
            "target_type"         => "required|in:all,active,selected",
            "selected_user_ids"   => "required_if:target_type,selected|array",
            "selected_user_ids.*" => "integer|exists:users,id",
        ]);

        if ($validator->fails()) {
            return response()->json([
                "success" => false,
                "message" => "Validation failed",
                "errors"  => $validator->errors(),
            ], 422);
        }

        $imageUrl = null;
        if ($request->hasFile("image")) {
            $path = $request->file("image")->store("notifications", "public");
            $imageUrl = asset("storage/" . $path);
        } elseif ($request->filled("image_url")) {
            $imageUrl = $request->input("image_url");
        }

        $targetType = $request->input("target_type");
        $selectedUserIds = $request->input("selected_user_ids", []);

        // Resolve Target Users
        $usersQuery = User::query();
        if ($targetType === "active") {
            // Active users (with active shop)
            $usersQuery->whereHas("shop", function ($q) {
                $q->where("status", "active");
            });
        } elseif ($targetType === "selected") {
            $usersQuery->whereIn("id", $selectedUserIds);
        }

        $targetUsers = $usersQuery->get();

        if ($targetUsers->isEmpty()) {
            return response()->json([
                "success" => false,
                "message" => "No users found matching the selected filter criteria.",
            ], 400);
        }

        DB::beginTransaction();
        try {
            // Create Push Notification record
            $pushNotification = PushNotification::create([
                "title"            => $request->input("title"),
                "description"      => $request->input("description"),
                "image_url"        => $imageUrl,
                "target_type"      => $targetType,
                "target_user_ids"  => $targetType === "selected" ? $selectedUserIds : null,
                "recipients_count" => $targetUsers->count(),
                "created_by"       => auth()->id(),
                "sent_at"          => now(),
            ]);

            // Bulk create user inbox notifications
            $now = now();
            $userNotificationsData = [];
            $fcmTokens = [];

            foreach ($targetUsers as $user) {
                $userNotificationsData[] = [
                    "user_id"              => $user->id,
                    "push_notification_id" => $pushNotification->id,
                    "title"                => $request->input("title"),
                    "description"          => $request->input("description"),
                    "image_url"            => $imageUrl,
                    "is_read"              => false,
                    "created_at"           => $now,
                    "updated_at"           => $now,
                ];

                if (!empty($user->fcm_token)) {
                    $fcmTokens[] = $user->fcm_token;
                }
            }

            foreach (array_chunk($userNotificationsData, 500) as $chunk) {
                UserNotification::insert($chunk);
            }

            DB::commit();

            // Send Firebase FCM Push if server key is configured in .env
            $this->sendFcmPushNotification($fcmTokens, $request->input("title"), $request->input("description"), $imageUrl);

            return response()->json([
                "success"          => true,
                "message"          => "Notification sent successfully to " . $targetUsers->count() . " user(s).",
                "recipients_count" => $targetUsers->count(),
                "data"             => $pushNotification,
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Failed to send broadcast push notification: " . $e->getMessage());

            return response()->json([
                "success" => false,
                "message" => "Server error occurred while sending notification: " . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Send Firebase Cloud Messaging (FCM) push notification to devices.
     */
    private function sendFcmPushNotification(array $tokens, string $title, string $description, ?string $imageUrl)
    {
        if (empty($tokens)) {
            return;
        }

        $serviceAccountPath = storage_path("app/firebase-service-account.json");
        $accessToken = null;
        $projectId = "repairhub-9b688";

        if (file_exists($serviceAccountPath)) {
            try {
                $serviceAccountData = json_decode(file_get_contents($serviceAccountPath), true);
                if (isset($serviceAccountData["project_id"])) {
                    $projectId = $serviceAccountData["project_id"];
                }

                if (empty($accessToken) && isset($serviceAccountData["client_email"], $serviceAccountData["private_key"])) {
            $header = json_encode(["alg" => "RS256", "typ" => "JWT"]);
            $now = time();
            $payload = json_encode([
                "iss"   => $serviceAccountData["client_email"],
                "scope" => "https://www.googleapis.com/auth/firebase.messaging",
                "aud"   => "https://oauth2.googleapis.com/token",
                "exp"   => $now + 3600,
                "iat"   => $now,
            ]);
            $b64H = str_replace(["+", "/", "="], ["-", "_", ""], base64_encode($header));
            $b64P = str_replace(["+", "/", "="], ["-", "_", ""], base64_encode($payload));
            $sig = "";
            openssl_sign($b64H . "." . $b64P, $sig, $serviceAccountData["private_key"], "SHA256");
            $b64S = str_replace(["+", "/", "="], ["-", "_", ""], base64_encode($sig));
            $jwt = $b64H . "." . $b64P . "." . $b64S;

            $chToken = curl_init("https://oauth2.googleapis.com/token");
            curl_setopt($chToken, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($chToken, CURLOPT_POST, true);
            curl_setopt($chToken, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($chToken, CURLOPT_POSTFIELDS, http_build_query([
                "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion"  => $jwt,
            ]));
            $tokenRes = curl_exec($chToken);
            curl_close($chToken);
            $tokenData = json_decode($tokenRes, true);
            $accessToken = $tokenData["access_token"] ?? null;
        }
            
            } catch (\Exception $ex) {
                Log::warning("FCM Service Account Error: " . $ex->getMessage());
            }
        }

        $uniqueTokens = array_unique(array_filter($tokens));

        // If HTTP v1 Access Token is available, use FCM v1 API
        if ($accessToken) {
            $v1Url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";
            $headers = [
                "Authorization: Bearer " . $accessToken,
                "Content-Type: application/json",
            ];

            foreach ($uniqueTokens as $token) {
                $payload = [
                    "message" => [
                        "token" => $token,
                        "notification" => [
                            "title" => $title,
                            "body"  => $description,
                            "image" => $imageUrl,
                        ],
                        "data" => [
                            "title"        => $title,
                            "body"         => $description,
                            "image"        => (string)$imageUrl,
                            "click_action" => "FLUTTER_NOTIFICATION_CLICK",
                        ],
                        "android" => [
                            "priority" => "HIGH",
                            "notification" => [
                                "sound" => "default",
                            ],
                        ],
                    ],
                ];

                try {
                    $ch = curl_init();
                    curl_setopt($ch, CURLOPT_URL, $v1Url);
                    curl_setopt($ch, CURLOPT_POST, true);
                    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    $res = curl_exec($ch); \Log::info("FCM v1 Response: " . $res);
                    curl_close($ch);
                } catch (\Exception $ex) {
                    Log::warning("FCM v1 Push Error: " . $ex->getMessage());
                }
            }
            return;
        }

        // Fallback to Legacy FCM API if FCM_SERVER_KEY is set
        $serverKey = env("FCM_SERVER_KEY");
        if ($serverKey) {
            $legacyUrl = "https://fcm.googleapis.com/fcm/send";
            $headers = [
                "Authorization: key=" . $serverKey,
                "Content-Type: application/json",
            ];

            foreach (array_chunk($uniqueTokens, 1000) as $chunk) {
                $payload = [
                    "registration_ids" => array_values($chunk),
                    "priority" => "high",
                    "content_available" => true,
                    "notification" => [
                        "title" => $title,
                        "body"  => $description,
                        "image" => $imageUrl,
                        "sound" => "default",
                    ],
                    "data" => [
                        "title"        => $title,
                        "body"         => $description,
                        "image"        => $imageUrl,
                        "click_action" => "FLUTTER_NOTIFICATION_CLICK",
                    ],
                ];

                try {
                    $ch = curl_init();
                    curl_setopt($ch, CURLOPT_URL, $legacyUrl);
                    curl_setopt($ch, CURLOPT_POST, true);
                    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
                    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
                    curl_exec($ch);
                    curl_close($ch);
                } catch (\Exception $ex) {
                    Log::warning("Legacy FCM Push Error: " . $ex->getMessage());
                }
            }
        }
    }

    /**
     * Delete a sent notification broadcast.
     */
    public function destroy($id): JsonResponse
    {
        $notification = PushNotification::find($id);
        if (!$notification) {
            return response()->json(["success" => false, "message" => "Notification not found"], 404);
        }

        $notification->delete();

        return response()->json([
            "success" => true,
            "message" => "Notification deleted successfully.",
        ]);
    }

    /**
     * API Endpoint for Mobile App users to fetch their inbox notifications.
     */
    public function userNotifications(Request $request): JsonResponse
    {
        $user = auth()->user();
        if (!$user) {
            return response()->json(["success" => false, "message" => "Unauthenticated"], 401);
        }

        $notifications = UserNotification::where("user_id", $user->id)
            ->latest()
            ->paginate($request->input("per_page", 20));

        $unreadCount = UserNotification::where("user_id", $user->id)
            ->where("is_read", false)
            ->count();

        return response()->json([
            "success"      => true,
            "unread_count" => $unreadCount,
            "data"         => $notifications,
        ]);
    }

    /**
     * Mark notification as read.
     */
    
    /**
     * Mark all user notifications as read.
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = auth()->user();
        UserNotification::where("user_id", $user->id)
            ->where("is_read", false)
            ->update([
                "is_read" => true,
                "read_at" => now(),
            ]);

        return response()->json([
            "success" => true,
            "message" => "All notifications marked as read",
        ]);
    }

    public function markAsRead(Request $request, $id): JsonResponse
    {
        $user = auth()->user();
        $notification = UserNotification::where("user_id", $user->id)->find($id);

        if (!$notification) {
            return response()->json(["success" => false, "message" => "Notification not found"], 404);
        }

        $notification->update([
            "is_read" => true,
            "read_at" => now(),
        ]);

        return response()->json([
            "success" => true,
            "message" => "Marked as read",
        ]);
    }

    /**
     * Save user FCM token.
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            "fcm_token" => "required|string",
        ]);

        if ($validator->fails()) {
            return response()->json(["success" => false, "errors" => $validator->errors()], 422);
        }

        $user = auth()->user();
        $user->fcm_token = $request->input("fcm_token"); $user->save();

        return response()->json([
            "success" => true,
            "message" => "FCM token updated successfully",
        ]);
    }
}
