package no.pgr301.exam.service;

import io.micrometer.core.instrument.MeterRegistry;
import no.pgr301.exam.model.AnalyzeResponse;
import no.pgr301.exam.model.GiftAnalysis;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class WishlistService {

    private final S3Service s3;
    private final RekognitionService rekognition;
    private final BedrockService bedrock;
    private final MeterRegistry registry ;

    public WishlistService(S3Service s3, RekognitionService rekognition, BedrockService bedrock,
                           MeterRegistry registry) {
        this.s3 = s3;
        this.rekognition = rekognition;
        this.bedrock = bedrock;
        this.registry = registry;
    }

    public AnalyzeResponse process(byte[] bytes, String filename, String contentType) {
        String s3Key = s3.upload(bytes, filename, contentType);
        List<String> labels = rekognition.detectLabels(bytes);
        GiftAnalysis analysis = bedrock.suggestGifts(labels);

        registry.counter("wishifai.images.analyzed", "roomType", roomType(labels)).increment();
        registry.counter("wishifai.gifts.suggested").increment(analysis.suggestions().size());

        return new AnalyzeResponse(
                s3Key,
                labels,
                analysis.roomAnalysis(),
                analysis.recipientProfile(),
                analysis.suggestions(),
                Instant.now().toString()
        );
    }

    private String roomType(List<String> labels) {
        Set<String> l = labels.stream().map(String::toLowerCase).collect(Collectors.toSet());
        if (l.contains("living room") || l.contains("couch") || l.contains("sofa")) return "stue";
        if (l.contains("garage") || l.contains("workbench") || l.contains("tool")) return "garasje";
        if (l.contains("toy") || l.contains("crib") || l.contains("nursery") || l.contains("teddy bear")) return "barnerom";
        return "annet";
    }
}
