using eCommerce.Model.Requests;
using eCommerce.Model.Responses;
using eCommerce.Model.SearchObjects;
using eCommerce.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace eCommerce.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Database.Reservation, ReservationUpsertRequest, ReservationUpsertRequest>, IReservationService
    {
        public ReservationService(eCommerceDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationUpsertRequest request)
        {
            var entity = new Database.Reservation();
            MapInsertToEntity(entity, request);
            _context.Set<Database.Reservation>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            
            // Reload entity with navigation properties
            entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == entity.Id);
            
            return MapToResponse(entity);
        }

        protected override IQueryable<Database.Reservation> ApplyFilter(IQueryable<Database.Reservation> query, ReservationSearchObject search)
        {
            query = query.Include(r => r.User)
                        .Include(r => r.Restaurant)
                        .Include(r => r.Table);

            if (search.UserId.HasValue)
            {
                query = query.Where(r => r.UserId == search.UserId.Value);
            }

            if (search.RestaurantId.HasValue)
            {
                query = query.Where(r => r.RestaurantId == search.RestaurantId.Value);
            }

            if (search.TableId.HasValue)
            {
                query = query.Where(r => r.TableId == search.TableId.Value);
            }

            if (!string.IsNullOrEmpty(search.Status))
            {
                query = query.Where(r => r.Status == search.Status);
            }

            if (search.ReservationDateFrom.HasValue)
            {
                query = query.Where(r => r.ReservationDate >= search.ReservationDateFrom.Value);
            }

            if (search.ReservationDateTo.HasValue)
            {
                query = query.Where(r => r.ReservationDate <= search.ReservationDateTo.Value);
            }

            return query;
        }

        protected override ReservationResponse MapToResponse(Database.Reservation entity)
        {
            if (entity == null)
                return null!;
                
            return new ReservationResponse
            {
                Id = entity.Id,
                UserId = entity.UserId,
                UserName = entity.User != null ? $"{entity.User.FirstName} {entity.User.LastName}" : string.Empty,
                RestaurantId = entity.RestaurantId,
                RestaurantName = entity.Restaurant != null ? entity.Restaurant.Name : string.Empty,
                TableId = entity.TableId,
                TableNumber = entity.Table != null ? entity.Table.TableNumber : string.Empty,
                ReservationDate = entity.ReservationDate,
                ReservationTime = entity.ReservationTime,
                NumberOfGuests = entity.NumberOfGuests,
                Status = entity.Status,
                SpecialRequests = entity.SpecialRequests,
                QRCode = entity.QRCode,
                CreatedAt = entity.CreatedAt,
                ConfirmedAt = entity.ConfirmedAt,
                CancelledAt = entity.CancelledAt,
                CancellationReason = entity.CancellationReason
            };
        }
        
        public override async Task<ReservationResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Reservations
                .Include(r => r.User)
                .Include(r => r.Restaurant)
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == id);
                
            if (entity == null)
                return null;
                
            return MapToResponse(entity);
        }
    }
}

