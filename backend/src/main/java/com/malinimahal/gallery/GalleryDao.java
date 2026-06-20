package com.malinimahal.gallery;

import com.malinimahal.db.Database;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

public class GalleryDao {

    public List<GalleryItem> listAll() throws SQLException {
        String sql = "SELECT * FROM gallery_items ORDER BY display_order, created_at DESC";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<GalleryItem> items = new ArrayList<>();
            while (rs.next()) items.add(mapRow(rs));
            return items;
        }
    }

    public GalleryItem findById(long id) throws SQLException {
        String sql = "SELECT * FROM gallery_items WHERE id = ?";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? mapRow(rs) : null;
            }
        }
    }

    public GalleryItem add(String mediaType, String filename, String youtubeUrl, String title)
            throws SQLException {
        String sql = """
                INSERT INTO gallery_items (media_type, filename, youtube_url, title)
                VALUES (?,?,?,?) RETURNING *
                """;
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, mediaType);
            ps.setString(2, filename);
            ps.setString(3, youtubeUrl);
            ps.setString(4, title);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return mapRow(rs);
            }
        }
    }

    public boolean remove(long id) throws SQLException {
        String sql = "DELETE FROM gallery_items WHERE id = ?";
        try (Connection conn = Database.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, id);
            return ps.executeUpdate() > 0;
        }
    }

    private GalleryItem mapRow(ResultSet rs) throws SQLException {
        GalleryItem item = new GalleryItem();
        item.setId(rs.getLong("id"));
        item.setMediaType(rs.getString("media_type"));
        String filename = rs.getString("filename");
        item.setFilename(filename);
        if (filename != null && filename.startsWith("https://")) {
            item.setMediaUrl(filename);
        }
        item.setYoutubeUrl(rs.getString("youtube_url"));
        item.setTitle(rs.getString("title"));
        item.setDisplayOrder(rs.getInt("display_order"));
        item.setCreatedAt(rs.getObject("created_at", OffsetDateTime.class));
        return item;
    }
}
