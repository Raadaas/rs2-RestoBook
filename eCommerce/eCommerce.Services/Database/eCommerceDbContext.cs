using Microsoft.EntityFrameworkCore;

namespace eCommerce.Services.Database
{
    public class eCommerceDbContext : DbContext
    {
        public eCommerceDbContext(DbContextOptions<eCommerceDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<CuisineType> CuisineTypes { get; set; }
        public DbSet<Restaurant> Restaurants { get; set; }
        public DbSet<RestaurantGallery> RestaurantGalleries { get; set; }
        public DbSet<MenuItem> MenuItems { get; set; }
        public DbSet<SpecialOffer> SpecialOffers { get; set; }
        public DbSet<Table> Tables { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<ReservationHistory> ReservationHistories { get; set; }
        public DbSet<Review> Reviews { get; set; }
        public DbSet<LoyaltyPoint> LoyaltyPoints { get; set; }
        public DbSet<PointsTransaction> PointsTransactions { get; set; }
        public DbSet<Reward> Rewards { get; set; }
        public DbSet<UserReward> UserRewards { get; set; }
        public DbSet<ChatConversation> ChatConversations { get; set; }
        public DbSet<ChatMessage> ChatMessages { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<RestaurantStatistic> RestaurantStatistics { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure User entity
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();
                
            // Configure City entity
            modelBuilder.Entity<City>()
                .HasIndex(c => c.Name)
                .IsUnique();
                
            // Configure CuisineType entity
            modelBuilder.Entity<CuisineType>()
                .HasIndex(ct => ct.Name)
                .IsUnique();
                
            // Configure Restaurant entity
            modelBuilder.Entity<Restaurant>()
                .HasIndex(r => r.Name);
                
            // Configure Restaurant-Owner relationship
            modelBuilder.Entity<Restaurant>()
                .HasOne(r => r.Owner)
                .WithMany(u => u.OwnedRestaurants)
                .HasForeignKey(r => r.OwnerId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure Restaurant-City relationship
            modelBuilder.Entity<Restaurant>()
                .HasOne(r => r.City)
                .WithMany(c => c.Restaurants)
                .HasForeignKey(r => r.CityId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure Restaurant-CuisineType relationship
            modelBuilder.Entity<Restaurant>()
                .HasOne(r => r.CuisineType)
                .WithMany(ct => ct.Restaurants)
                .HasForeignKey(r => r.CuisineTypeId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure RestaurantGallery relationship
            modelBuilder.Entity<RestaurantGallery>()
                .HasOne(rg => rg.Restaurant)
                .WithMany(r => r.Gallery)
                .HasForeignKey(rg => rg.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure MenuItem relationship
            modelBuilder.Entity<MenuItem>()
                .HasOne(mi => mi.Restaurant)
                .WithMany(r => r.MenuItems)
                .HasForeignKey(mi => mi.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure MenuItem Category enum (stored as int in database)
            modelBuilder.Entity<MenuItem>()
                .Property(mi => mi.Category)
                .HasConversion<int?>();
                
            // Configure MenuItem Allergens enum (stored as int in database)
            modelBuilder.Entity<MenuItem>()
                .Property(mi => mi.Allergens)
                .HasConversion<int>();
                
            // Configure SpecialOffer relationship
            modelBuilder.Entity<SpecialOffer>()
                .HasOne(so => so.Restaurant)
                .WithMany(r => r.SpecialOffers)
                .HasForeignKey(so => so.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure Table relationships
            modelBuilder.Entity<Table>()
                .HasOne(t => t.Restaurant)
                .WithMany(r => r.Tables)
                .HasForeignKey(t => t.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure TableType as enum (stored as int in database)
            modelBuilder.Entity<Table>()
                .Property(t => t.TableType)
                .HasConversion<int?>();
                
            // Configure Reservation relationships
            modelBuilder.Entity<Reservation>()
                .HasOne(res => res.User)
                .WithMany(u => u.Reservations)
                .HasForeignKey(res => res.UserId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<Reservation>()
                .HasOne(res => res.Restaurant)
                .WithMany(r => r.Reservations)
                .HasForeignKey(res => res.RestaurantId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<Reservation>()
                .HasOne(res => res.Table)
                .WithMany(t => t.Reservations)
                .HasForeignKey(res => res.TableId)
                .OnDelete(DeleteBehavior.SetNull);
                
            // Configure Reservation-Review one-to-one relationship
            modelBuilder.Entity<Reservation>()
                .HasOne(res => res.Review)
                .WithOne(rev => rev.Reservation)
                .HasForeignKey<Review>(rev => rev.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure ReservationHistory relationships
            modelBuilder.Entity<ReservationHistory>()
                .HasOne(rh => rh.Reservation)
                .WithMany(res => res.History)
                .HasForeignKey(rh => rh.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);
                
            modelBuilder.Entity<ReservationHistory>()
                .HasOne(rh => rh.ChangedByUser)
                .WithMany(u => u.ChangedReservationHistories)
                .HasForeignKey(rh => rh.ChangedByUserId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure Review relationships
            modelBuilder.Entity<Review>()
                .HasOne(rev => rev.User)
                .WithMany(u => u.Reviews)
                .HasForeignKey(rev => rev.UserId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<Review>()
                .HasOne(rev => rev.Restaurant)
                .WithMany(r => r.Reviews)
                .HasForeignKey(rev => rev.RestaurantId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure LoyaltyPoint relationship
            modelBuilder.Entity<LoyaltyPoint>()
                .HasOne(lp => lp.User)
                .WithOne(u => u.LoyaltyPoint)
                .HasForeignKey<LoyaltyPoint>(lp => lp.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            // Configure PointsTransaction relationships
            modelBuilder.Entity<PointsTransaction>()
                .HasOne(pt => pt.User)
                .WithMany(u => u.PointsTransactions)
                .HasForeignKey(pt => pt.UserId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<PointsTransaction>()
                .HasOne(pt => pt.LoyaltyPoint)
                .WithMany(lp => lp.Transactions)
                .HasForeignKey(pt => pt.LoyaltyPointId)
                .OnDelete(DeleteBehavior.Cascade);
                
            modelBuilder.Entity<PointsTransaction>()
                .HasOne(pt => pt.Reservation)
                .WithMany()
                .HasForeignKey(pt => pt.ReservationId)
                .OnDelete(DeleteBehavior.SetNull)
                .IsRequired(false);
                
            // Configure Reward relationship
            modelBuilder.Entity<Reward>()
                .HasOne(rw => rw.Restaurant)
                .WithMany(r => r.Rewards)
                .HasForeignKey(rw => rw.RestaurantId)
                .OnDelete(DeleteBehavior.SetNull)
                .IsRequired(false);
                
            // Configure UserReward relationships
            modelBuilder.Entity<UserReward>()
                .HasOne(ur => ur.User)
                .WithMany(u => u.UserRewards)
                .HasForeignKey(ur => ur.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            modelBuilder.Entity<UserReward>()
                .HasOne(ur => ur.Reward)
                .WithMany(rw => rw.UserRewards)
                .HasForeignKey(ur => ur.RewardId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure ChatConversation relationships
            modelBuilder.Entity<ChatConversation>()
                .HasOne(cc => cc.User)
                .WithMany(u => u.ChatConversations)
                .HasForeignKey(cc => cc.UserId)
                .OnDelete(DeleteBehavior.Restrict);
                
            modelBuilder.Entity<ChatConversation>()
                .HasOne(cc => cc.Restaurant)
                .WithMany(r => r.ChatConversations)
                .HasForeignKey(cc => cc.RestaurantId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure ChatMessage relationships
            modelBuilder.Entity<ChatMessage>()
                .HasOne(cm => cm.Conversation)
                .WithMany(cc => cc.Messages)
                .HasForeignKey(cm => cm.ConversationId)
                .OnDelete(DeleteBehavior.Cascade);
                
            modelBuilder.Entity<ChatMessage>()
                .HasOne(cm => cm.Sender)
                .WithMany(u => u.SentMessages)
                .HasForeignKey(cm => cm.SenderId)
                .OnDelete(DeleteBehavior.Restrict);
                
            // Configure Notification relationships
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany(u => u.Notifications)
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);
                
            modelBuilder.Entity<Notification>()
                .HasOne(n => n.RelatedReservation)
                .WithMany()
                .HasForeignKey(n => n.RelatedReservationId)
                .OnDelete(DeleteBehavior.SetNull)
                .IsRequired(false);
                
            // Configure RestaurantStatistic relationship
            modelBuilder.Entity<RestaurantStatistic>()
                .HasOne(rs => rs.Restaurant)
                .WithMany(r => r.Statistics)
                .HasForeignKey(rs => rs.RestaurantId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
} 