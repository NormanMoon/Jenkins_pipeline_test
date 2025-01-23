package utils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ticket_cleaner {


    public static void main(String[] args) {

        // Add all ticket from command line args (skipping the application name)
        List<String> tickets = new ArrayList<>(Arrays.asList(args));

        List<String> cleanedTickets = cleanTickets(tickets);

        // Print the cleaned ticket as a space-separated string
        System.out.println(String.join(" ", cleanedTickets));
    }

    public static List<String> cleanTickets(List<String> tickets) {
        // Clean the services by removing unwanted characters
        List<String> cleanedTickets = new ArrayList<>();
        for (String service : tickets) {
            String cleaned = service.replaceAll("[\\[\\],]", "");
            cleanedTickets.add(cleaned);
        }

        return cleanedTickets;
    }
}

