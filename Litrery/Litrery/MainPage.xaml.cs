using Litrery.DataAccess;

namespace Litrery;

public partial class MainPage : ContentPage
{
    int count = 0;

    public MainPage()
    {
        InitializeComponent();
        Loaded += OnPageLoaded;
    }

    private async void OnPageLoaded(object? sender, EventArgs e)
    {
        var repo = new VehicleRepository();
        var vehicles = await repo.ReadVehicles();
        foreach (var vehicle in vehicles)
        {
            Console.WriteLine(vehicle.Make);
        }
    }

    private void OnCounterClicked(object? sender, EventArgs e)
    {
        count++;

        if (count == 1)
            CounterBtn.Text = $"Clicked {count} time";
        else
            CounterBtn.Text = $"Clicked {count} times";

        SemanticScreenReader.Announce(CounterBtn.Text);
    }
}