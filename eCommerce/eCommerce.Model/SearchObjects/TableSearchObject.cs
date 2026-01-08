using eCommerce.Model;

namespace eCommerce.Model.SearchObjects
{
    public class TableSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? TableNumber { get; set; }
        public int? Capacity { get; set; }
        public TableType? TableType { get; set; }
        public bool? IsActive { get; set; }
    }
}

