using System;

namespace eCommerce.Model.Responses
{
    public class ReservationHistoryResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public string? StatusChangedFrom { get; set; }
        public string StatusChangedTo { get; set; } = string.Empty;
        public DateTime ChangedAt { get; set; }
        public int ChangedByUserId { get; set; }
        public string ChangedByUserName { get; set; } = string.Empty;
        public string? Notes { get; set; }
    }
}

