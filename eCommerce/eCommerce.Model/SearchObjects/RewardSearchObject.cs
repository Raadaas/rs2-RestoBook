namespace eCommerce.Model.SearchObjects
{
    public class RewardSearchObject : BaseSearchObject
    {
        public int? RestaurantId { get; set; }
        public string? Title { get; set; }
        public bool? IsActive { get; set; }
    }
}
