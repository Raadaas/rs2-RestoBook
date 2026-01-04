namespace eCommerce.Model.SearchObjects
{
    public class TableSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? TableNumber { get; set; }
        public int? Capacity { get; set; }
        public string? TableType { get; set; }
        public bool? IsActive { get; set; }
    }
}

