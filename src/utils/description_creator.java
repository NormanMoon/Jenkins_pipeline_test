package utils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class description_creator {
    public static void main(String[] args) {

        if (args.length < 6) {
            System.err.println("Error: Expected at least 6 arguments but got " + args.length);
            return;
        }

        String environment = args[0];
        String application = args[1];
        String image = args[2];
        String appVersion = args[3];
        String releaseType = args[4];
        String vaultDescription = args[5];
        // Add all inputs starting from index 6
        List<String> allInputs = new ArrayList<>(Arrays.asList(args).subList(6, args.length));

        // Define a list of service keywords to exclude from child_tickets
        // List of prefixes for child tickets
        List<String> ticketPrefixes = Arrays.asList("POP", "NGD", "ECCB");
        List<String> servicesKeyWords = Arrays.asList("Main", "HFD", "Deployment", "Veteran", "Consul", "Staff", "Other");

        // Separate child tickets and summaries
        List<String> child_tickets = new ArrayList<>();
        List<String> summaries = new ArrayList<>();
        List<String> services = new ArrayList<>();

        for (String item : allInputs) {
            // Check if the item starts with any prefix in ticketPrefixes
            boolean isChildTicket = ticketPrefixes.stream().anyMatch(item::startsWith);
            boolean isService = servicesKeyWords.stream().anyMatch(item::startsWith);

            if (isChildTicket) {
                child_tickets.add(item);
            } else if (isService) {
                services.add(item);
            } else {
                summaries.add(item.trim());
            }
        }
        System.err.println("Child Ticket Ids for description creator: " + child_tickets);
        System.err.println("All Inputs for description creator: " + allInputs);
        System.err.println("Summaries for description creator: " + summaries);
        System.err.println("Services for description creator: " + services);

        /*
        System.out.println(environment);
        System.out.println(application);
        System.out.println(image);
        System.out.println(appVersion);
        System.out.println(releaseType);
        System.out.println(vaultDescription);
        System.out.println(summaries);
        System.out.println(child_tickets);
         */
        // Generate ticket descriptions
        String descriptions = "";
        if (environment.equalsIgnoreCase("Prod") || environment.equalsIgnoreCase("Prod-Beta")) {
            descriptions = generateTicketDescriptionsForProd(
                    environment, application, image, appVersion, vaultDescription, releaseType, summaries, child_tickets, services);
        } else {
            descriptions = generateTicketDescriptionForSQA(environment, application, image, appVersion, vaultDescription, services);

        }

        // Print the descriptions
        System.out.println(descriptions);
    }

    public static String generateTicketDescriptionForSQA(
            String environment,
            String application,
            String image,
            String appVersion,
            String vaultDescription,
            List<String> services
    ) {
        StringBuilder description = new StringBuilder();
        for (String service : services) {
            if (service.equalsIgnoreCase("Deployment")) {
                description.append(String.format("%s: Deploy %s config for %s in %s",
                        environment, service, image, environment)).append("|");
            } else if (service.equalsIgnoreCase("Vault")){
                description.append(vaultDescription).append("|");
            } else {
                description.append(String.format("%s: Change %s config for %s in %s",
                        environment, service, image, environment)).append("|");
            }
        }

        return description.toString();
    }

    public static String generateTicketDescriptionsForProd(
            String environment,
            String application,
            String image,
            String appVersion,
            String vaultDescription,
            String releaseType,
            List<String> summaries,
            List<String> child_tickets,
            List<String> services
    ) {
        StringBuilder descriptions = new StringBuilder();
        String nextStep = " *<---- This sub-task is for this step* ⭐";

        // Initialize parent ticket description
        StringBuilder parentDescription = new StringBuilder();
        parentDescription.append(summaries.get(0));
        for (int i = 0; i < services.size(); i++) {
            parentDescription.append("\\n").
                    append(child_tickets.get(i + 1)).
                    append(" ").
                    append(summaries.get(i + 1));
        }

        descriptions.append(parentDescription.toString());
        descriptions.append("|");

        for (int i = 0; i < services.size(); i++) {
            StringBuilder current_child_description = new StringBuilder();
            current_child_description.append(firstLineOfChild(environment,
                    application,
                    image,
                    appVersion,
                    vaultDescription,
                    services.get(i))).append("\\n\\n").append("*Sequence of Steps :*");
            for (int j = 0; j < services.size(); j++) {
                current_child_description.append("\\n").
                        append(child_tickets.get(j + 1)).
                        append(" ").
                        append(summaries.get(j + 1));
                if (i == j) {
                    current_child_description.append(nextStep);
                }
            }
            descriptions.append(current_child_description.toString());
            descriptions.append("|");
        }

        return descriptions.toString();
    }



    public static String firstLineOfChild(
            String environment,
            String application,
            String image,
            String appVersion,
            String vaultDescription,
            String service
    ) {
        String firstLineOfChild = "";
        if ("vault".equalsIgnoreCase(service)) {
            firstLineOfChild = String.format(
                    "%s \\n \\n Deploy: %s:%s to %s",
                    vaultDescription, image, appVersion, service
            );
        } else if ("main".equalsIgnoreCase(service) || "hfd".equalsIgnoreCase(service)) {
            firstLineOfChild = String.format(
                    " Deploy %s:%s for %s to %s",
                    image, appVersion, application, service
            );
        } else if ("deployment".equalsIgnoreCase(service)) {
            firstLineOfChild = String.format(
                    " %s: Deploy %s:%s for %s",
                    environment, image, appVersion, application
            );
        } else if ("other".equalsIgnoreCase(service)) {
            firstLineOfChild = "";
        }
        else {
            firstLineOfChild = String.format(
                    " %s: Change %s:%s config for %s in %s",
                    environment, image, appVersion, application, environment
            );
        }
        return firstLineOfChild;
    }

    public static void descriptionToString(List<String> descriptions) {

        for (String description : descriptions) {
            System.out.println(description);
            System.out.println("\n");
        }
    }

}

