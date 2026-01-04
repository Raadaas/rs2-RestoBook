namespace eCommerce.Model.SearchObjects
{
    public class ReservationHistorySearchObject : BaseSearchObject
    {
        public int? ReservationId { get; set; }
        public int? ChangedByUserId { get; set; }
        public string? StatusChangedTo { get; set; }
    }
}

