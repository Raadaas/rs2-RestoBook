using System;

namespace eCommerce.Model.Messages
{
    /// <summary>
    /// Published when a reservation's status changes (confirm / cancel / complete).
    /// Consumer can create a Notification for the user.
    /// </summary>
    public class ReservationStatusChangedMessage
    {
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public string PreviousState { get; set; } = string.Empty;
        public string NewState { get; set; } = string.Empty;
        public string RestaurantName { get; set; } = string.Empty;
        public DateTime ReservationDate { get; set; }
        public TimeSpan ReservationTime { get; set; }
        public string? CancellationReason { get; set; }
        /// <summary>When > 0, notification goes to this user (admin). When 0, goes to UserId (client).</summary>
        public int RecipientUserId { get; set; }
        /// <summary>Client name for admin-facing notification text.</summary>
        public string? ClientName { get; set; }
    }
}
