#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdio>
#include <vector>
#include <string>

const char* path = DATA_PATH "/Data.bin";

struct MappedFile {
    unsigned char* data;
    size_t         size;
};

MappedFile loadData(const char* path) {
    int fd = ::open(path, O_RDONLY);
    off_t size = ::lseek(fd, 0, SEEK_END);
    void* mem = ::mmap(nullptr, size, PROT_READ, MAP_PRIVATE, fd, 0);
    return { reinterpret_cast<unsigned char*>(mem), static_cast<size_t>(size) };
}

int main(int argc, char* argv[]) {
    // 1) Load entire file via mmap (zero‐copy)
    auto mf = loadData(path);
    unsigned char* ptr = mf.data;
    unsigned char* end = mf.data + mf.size;

    // 2) Read header
    size_t numHashes = *reinterpret_cast<size_t*>(ptr);
    ptr += sizeof(size_t);

    // 3) Prepare output buffer (reserve enough for ~20 chars per hash + newline)
    std::vector<char> out;
    out.reserve(numHashes * 24);

    // 4) Precompute multiplier table
    using Hash = unsigned long long;
    constexpr Hash INITIAL   = 104395301ULL;
    constexpr Hash MULTIPLIER = 2654435789ULL;
    Hash multTab[256];
    for (int b = 0; b < 256; ++b)
        multTab[b] = MULTIPLIER * Hash(b);

    // 5) Hash loop: pointer‐walk + table lookup + fast integer ops
    for (size_t i = 0; i < numHashes; ++i) {
        size_t numBytes = *reinterpret_cast<size_t*>(ptr);
        ptr += sizeof(size_t);

        unsigned char*   bptr = ptr;
        unsigned char*   bend = bptr + numBytes;
        Hash             hash = INITIAL;

        // tight while‐loop, no bounds checks beyond pointer compare
        while (bptr < bend) {
            // replace mul with lookup, xor + shift are single‐cycle ops
            hash += multTab[*bptr] ^ (hash >> 23);
            ++bptr;
        }
        ptr = bend;

        // 6) append "<hash>\n" via fast itoa + push_back
        //    avoid std::to_string (allocates) and iostreams entirely
        char buf[32];
        int  len = std::snprintf(buf, sizeof(buf), "%llu\n", (unsigned long long)hash);
        out.insert(out.end(), buf, buf + len);
    }

    // 7) write all at once
    int outfd = ::open(std::string(argv[0]).append(".txt").c_str(),
                       O_CREAT | O_TRUNC | O_WRONLY, 0644);
    ::write(outfd, out.data(), out.size());
    ::close(outfd);

    return 0;
}

