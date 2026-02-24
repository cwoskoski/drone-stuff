package com.example.drone_stuff;

interface IFileService {
    List<String> listFiles(String path);
    byte[] readFile(String path);
    boolean writeFile(String path, in byte[] bytes);
    long fileSize(String path);
    boolean exists(String path);
    boolean deleteFile(String path);
    void destroy();
}
