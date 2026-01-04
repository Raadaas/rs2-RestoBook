using System;

namespace eCommerce.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? RestaurantId { get; set; }
        public int? TableId { get; set; }
        public string? Status { get; set; }
        public DateTime? ReservationDateFrom { get; set; }
        public DateTime? ReservationDateTo { get; set; }
    }
}

