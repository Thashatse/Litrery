using Litrery.Models;

namespace Litrery.Pages;

public partial class VehicleDetailPage : ContentPage
{
    private readonly Vehicle _vehicle;

    public VehicleDetailPage(Vehicle vehicle)
    {
        InitializeComponent();
        _vehicle = vehicle;
        Title = vehicle.Model;
    }

    protected override void OnAppearing()
    {
        base.OnAppearing();
        LoadVehicle();
    }

    private void LoadVehicle()
    {
        VehicleMakeLabel.Text = $"{_vehicle.Make}";
        VehicleModelLabel.Text = $"{_vehicle.Model}";
        VehicleYearRegLabel.Text = $"{_vehicle.Year} · {_vehicle.RegistrationNumber}";
        OdometerLabel.Text = $"{_vehicle.Odometer:N0} km";

        var logs = _vehicle.Logs ?? [];

        // Stats
        var validConsumption = logs.Where(l => l.LPer100Km.HasValue).ToList();
        var validCost = logs.Where(l => l.CostZar.HasValue).ToList();

        AvgConsumptionLabel.Text = validConsumption.Any()
            ? $"{validConsumption.Average(l => l.LPer100Km!.Value):N1}"
            : "--";

        AvgCostLabel.Text = validCost.Any()
            ? $"R{validCost.Average(l => l.CostZar!.Value):N0}"
            : "--";

        TotalFillsLabel.Text = logs.Count.ToString();
        
        // Average days between fill-ups
        if (logs.Count >= 2)
        {
            var sorted = logs.OrderByDescending(l => l.Date).ToList();
            var gaps = sorted.Zip(sorted.Skip(1), (a, b) => (a.Date - b.Date).TotalDays);
            var avgDays = gaps.Average();
            AvgDaysLabel.Text = $"{avgDays:N1}d";
        }
        else
        {
            AvgDaysLabel.Text = "--";
        }

        // Sort newest first
        LogList.ItemsSource = logs.OrderByDescending(l => l.Date).ToList();
    }

    private async void OnAddFillUpClicked(object? sender, EventArgs e)
    {
        await Navigation.PushModalAsync(new NavigationPage(new AddLogPage(_vehicle)));
    }
}