namespace eCommerce.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public int? ReservationId { get; set; }
        public int? UserId { get; set; }
        public int? RestaurantId { get; set; }
        public int? Rating { get; set; }
        public bool? IsVerified { get; set; }
    }
}

